import UIKit
import HealthKit

class SCHTableCell: UITableViewCell {

  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var detailLabel: UILabel!
  @IBOutlet weak var imageLabel: UIImageView!
}

class WorkoutsTableViewController: UITableViewController {

  private enum WorkoutsSegues: String {
    case detailViewSegue
    case finishedCreatingWorkout
  }

  lazy private var workoutStore: WorkoutDataStore = {
    return WorkoutDataStore()
  }()

  private var workouts: [HKWorkout]?
  private var tableSections: [String]?
  private var workoutSections:[String: [HKWorkout]] = [:]
  private let tableCell = "SCHtableCellID"

  lazy var dateFormatter:DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.dateStyle = .medium
    return formatter
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    self.refreshControl?.addTarget(self, action: #selector(handleRefresh(refreshControl:)), for: UIControlEvents.valueChanged)
    authorizeHealthKit()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    reloadWorkouts()
  }

  func reloadWorkouts() {

    workoutStore.loadWorkouts() { (workouts, error) in
      if let appleWorkouts = workouts?.filter({$0.sourceRevision.description.contains("com.apple.health")}){
        self.workouts = appleWorkouts
        self.tableSections = []

        self.workoutSections = [:]
        for workout in appleWorkouts {
          let key = "\(workout.startDate.year) -- \(workout.startDate.month)"
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

  @objc func handleRefresh(refreshControl: UIRefreshControl) {
    reloadWorkouts()
    self.tableView.reloadData()
    refreshControl.endRefreshing()
  }

  //MARK: UITableView DataSource
  override func numberOfSections(in tableView: UITableView) -> Int {
    return workoutSections.count
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

    if let key = tableSections?[section], let workouts = workoutSections[key]{
      return workouts.count
    } else {
      return 0
    }
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

    let cell = tableView.dequeueReusableCell(withIdentifier: tableCell, for: indexPath) as! SCHTableCell

    if let section = tableSections?[indexPath.section] {

      let workout = workoutSections[section]![indexPath.row]
      cell.titleLabel.text = dateFormatter.string(from: workout.startDate)

      if let totalDistance = workout.totalDistance?.doubleValue(for: HKUnit.meter()){
        let totalTime = workout.duration
        let displayTime = stringFromTimeInterval(interval: totalTime)
        let displayText = String(format: "Distance: %.2fkm - Duration: \(displayTime)", totalDistance / 1000)

        cell.detailLabel.text = displayText
      } else {
        cell.detailLabel.text = nil
      }

      switch workout.workoutActivityType {
        case .running: cell.imageLabel.image = #imageLiteral(resourceName: "Run")
        case .cycling: cell.imageLabel.image = #imageLiteral(resourceName: "Cycle")
        case .swimming: cell.imageLabel.image = #imageLiteral(resourceName: "Swim")
        case .walking: cell.imageLabel.image = #imageLiteral(resourceName: "Still")
        default: cell.imageLabel.image = #imageLiteral(resourceName: "Default")
      }

      return cell
    }
    return cell
  }


  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    if let title = tableSections?[section] {
      return title
    } else {
      return ""
    }
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

  }

  // MARK: Segues
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let idx = self.tableView.indexPathForSelectedRow,
      let section = tableSections?[idx.section],
      let workout = workoutSections[section]?[idx.row],
      let dvc = segue.destination.childViewControllers.first as? WorkoutDetailViewController {
        dvc.hkWorkout = workout
    }
  }

  @IBAction func unwindToTableView(segue:UIStoryboardSegue) { }


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

  private func stringFromTimeInterval(interval: Double) -> String {

    let hours = (Int(interval) / 3600)
    let minutes = Int(interval / 60) - Int(hours * 60)
    let seconds = Int(interval) - (Int(interval / 60) * 60)

    return String(format: "%0.2d:%0.2d:%0.2d",hours,minutes,seconds)
  }
}
