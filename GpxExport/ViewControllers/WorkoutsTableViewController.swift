import UIKit
import HealthKit

class WorkoutsTableViewController: UITableViewController {
    private enum WorkoutsSegues: String {
        case detailViewSegue
        case finishedCreatingWorkout
    }

    @IBOutlet weak var sharingBarButtonItem: UIBarButtonItem!

    lazy private var workoutStore: WorkoutDataStore = {
        return WorkoutDataStore()
    }()

    private let group = DispatchGroup()
    private var workouts: [HKWorkout]?
    private var tableSections: [String]?
    private var workoutSections = [String: [HKWorkout]]()
    private let tableCellIdentifier = "WorkoutTableViewCell"

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        authorizeHealthKit()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        reloadWorkouts()
    }

    // MARK: Data source

    func reloadWorkouts() {
        workoutStore.loadWorkouts { (workouts, _) in
            if let appleWorkouts = workouts?.filter({
                if let filter = $0.sourceRevision.productType?.contains("Watch") {
                    return filter
                } else {
                    return false
                }
            }) {
                self.workouts = appleWorkouts
                self.tableSections = []

                self.workoutSections = [:]
                for workout in appleWorkouts {
                    let key = workout.formattedStartDateForSection
                    if self.workoutSections[key] == nil {
                        self.workoutSections[key] = [workout]
                        self.tableSections?.append(key)
                    } else {
                        self.workoutSections[key]?.append(workout)
                    }
                }
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    private func authorizeHealthKit() {
        HealthKitSetupAssistant.authorizeHealthKit { (authorized, error) in
            guard authorized else {
                let baseMessage = "HealthKit Authorization Failed"

                if let error = error {
                    print("\(baseMessage). Reason: \(error.localizedDescription)")
                } else {
                    print(baseMessage)
                }

                return
            }

            print("HealthKit Successfully Authorized.")
        }
    }

    @objc func handleRefresh(refreshControl: UIRefreshControl) {
        reloadWorkouts()
        self.tableView.reloadData()
        refreshControl.endRefreshing()
    }

    private func exportSelectedWorkouts() {
        let alert = UIAlertController(title: "What file to generate?", message: "It's recommended to use GPX for now.", preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "GPX", style: .default, handler: {(_: UIAlertAction!) in
            self.handleExport("GPX")
        }))
        alert.addAction(UIAlertAction(title: "Fit", style: .default, handler: {(_: UIAlertAction!) in
            //Sign out action
            self.handleExport("Fit")
        }))

        self.present(alert, animated: true)
    }
    private func handleExport(_ format: String) {
        guard let selectedWorkouts = tableView.indexPathsForSelectedRows else { return }

        var workouts = [Workout]()

        for index in selectedWorkouts {
            if let section = tableSections?[index.section], let workout = workoutSections[section]?[index.row] {
                group.enter()
                workoutStore.heartRate(for: workout) { (rates, error) in
                    guard let heartRateSamples = rates, error == nil else {
                        print(error!.localizedDescription)
                        return
                    }

                    self.workoutStore.route(for: workout) { (maybeLocations, error) in
                        guard let locations = maybeLocations, error == nil else {
                            print(error!.localizedDescription)
                            return
                        }

                        workouts.append(Workout(workout: workout, route: locations, heartRate: heartRateSamples))
                        self.group.leave()
                    }
                }
            }
        }

        group.wait()

        var targetURLs = [URL]()

        for workout in workouts {
            if let targetURL = workout.writeFile(format) {
                targetURLs.append(targetURL)
            }
        }

        if targetURLs.count > 0 {
            let activityViewController = UIActivityViewController(activityItems: targetURLs, applicationActivities: nil)
            if let popoverPresentationController = activityViewController.popoverPresentationController {
                popoverPresentationController.barButtonItem = nil
            }
            self.present(activityViewController, animated: true)
        }
    }

    // MARK: UI

    private func setupUI() {
        self.tableView.register(UINib(nibName: "WorkoutTableViewCell", bundle: nil), forCellReuseIdentifier: tableCellIdentifier)

        self.refreshControl?.addTarget(self, action: #selector(handleRefresh(refreshControl:)), for: UIControl.Event.valueChanged)

        self.navigationController?.setToolbarHidden(true, animated: false)

        sharingBarButtonItem.isEnabled = false
        setBarButtonItems()
    }

    private func setBarButtonItems() {
        if self.tableView.isEditing {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(setEditTable(_:)))
        } else {
            let buttonTitle = NSLocalizedString("bar.button.select", comment: "Bar Button: Select Workouts")
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: buttonTitle,
                                                                     style: .plain,
                                                                     target: self,
                                                                     action: #selector(setEditTable(_:)))
        }
    }

    @IBAction func setEditTable(_ sender: Any) {
        sharingBarButtonItem.isEnabled = false

        if self.tableView.isEditing {
            self.tableView.setEditing(false, animated: true)
            self.navigationController?.setToolbarHidden(true, animated: true)
        } else {
            self.tableView.setEditing(true, animated: true)
            self.navigationController?.setToolbarHidden(false, animated: true)
        }

        setBarButtonItems()
    }

    @IBAction func didPressShareBarButtonItem(_ sender: UIBarButtonItem) {
        exportSelectedWorkouts()
    }

    private func setSharingBarButtonItem() {
        if let selectedWorkouts = tableView.indexPathsForSelectedRows, selectedWorkouts.count > 0 {
            sharingBarButtonItem.isEnabled = true
        } else {
            sharingBarButtonItem.isEnabled = false
        }
    }

    // MARK: UITableViewDataSource, UITableViewDelegate

    override func numberOfSections(in tableView: UITableView) -> Int {
        return workoutSections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let key = tableSections?[section], let workouts = workoutSections[key] {
            return workouts.count
        } else {
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableCellIdentifier, for: indexPath)

        if let section = tableSections?[indexPath.section], let workout = workoutSections[section]?[indexPath.row] {
            configureWorkoutTableViewCell(cell, with: workout)
        }

        return cell
    }

    private func configureWorkoutTableViewCell(_ cell: UITableViewCell, with workout: HKWorkout) {
        guard let cell = cell as? WorkoutTableViewCell else { return }

        cell.dateLabel.text = workout.formattedStartDate
        cell.workoutTypeLabel.text = workout.formattedWorkoutType
        cell.distanceLabel.text = workout.formattedTotalDistance
        cell.durationLabel.text = workout.duration.formatted

        switch workout.workoutActivityType {
        case .running: cell.imageLabel.image = #imageLiteral(resourceName: "Run")
        case .cycling: cell.imageLabel.image = #imageLiteral(resourceName: "Cycle")
        case .swimming: cell.imageLabel.image = #imageLiteral(resourceName: "Swim")
        case .walking: cell.imageLabel.image = #imageLiteral(resourceName: "Still")
        case .hiking: cell.imageLabel.image = #imageLiteral(resourceName: "Hike")
        default: cell.imageLabel.image = #imageLiteral(resourceName: "Default")
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            setSharingBarButtonItem()
        } else {
            self.performSegue(withIdentifier: WorkoutsSegues.detailViewSegue.rawValue, sender: indexPath)
        }
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            setSharingBarButtonItem()
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return tableSections?[section]
    }

    // MARK: Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else { return }

        if identifier == WorkoutsSegues.detailViewSegue.rawValue,
            let workoutDetailTableViewController = segue.destination as? WorkoutDetailTableViewController {
            guard let indexPath = sender as? IndexPath else { return }

            if let section = tableSections?[indexPath.section], let workout = workoutSections[section]?[indexPath.row] {
                workoutDetailTableViewController.hkWorkout = workout
            }
        }
    }
}
