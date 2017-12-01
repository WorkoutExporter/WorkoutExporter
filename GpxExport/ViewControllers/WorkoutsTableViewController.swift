import UIKit
import HealthKit
import WatchKit

class WorkoutsTableViewController: UITableViewController {

  private enum WorkoutsSegues: String {
    case showCreateWorkout
    case finishedCreatingWorkout
  }

  lazy private var workoutStore: WorkoutDataStore = {
    return WorkoutDataStore()
  }()

  private var workouts: [HKWorkout]?

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
    return 1
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

    guard let workouts = workouts else {
      return 0
    }

    return workouts.count
  }


  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    guard let workouts = self.workouts else {
      return
    }

    if (indexPath.row >= workouts.count){
      return
    }

    let workout = workouts[indexPath.row]

    workoutStore.heartRate(for: workouts[indexPath.row]){
      (rates, error) in

      guard let heartRateSamples = rates, error == nil else {
        print(error as Any)
        return
      }

      self.workoutStore.route(for: workouts[indexPath.row]){
        (maybe_locations, error) in
        guard let locations = maybe_locations, error == nil else {
          print(error as Any)
          return
        }

        let workout = Workout(workout: workout, route: locations, heartRate: heartRateSamples)
        if let targetURL = workout.writeFile() {


          let activityViewController = UIActivityViewController(
            activityItems: [targetURL],
            applicationActivities: nil)
          if let popoverPresentationController = activityViewController.popoverPresentationController {
            popoverPresentationController.barButtonItem = nil
          }
          self.present(activityViewController, animated: true, completion: nil)
        }
      }
    }
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

    guard let workouts = workouts else {
      fatalError("CellForRowAtIndexPath should never get called if there are no workouts")
    }

    let cell = tableView.dequeueReusableCell(withIdentifier: tableCell, for: indexPath)
    let workout = workouts[indexPath.row]
    cell.textLabel?.text = dateFormatter.string(from: workout.startDate)

    if let totalDistance = workout.totalDistance?.doubleValue(for: HKUnit.meter()){
      let totalTime = workout.duration
      let displayTime = stringFromTimeInterval(interval: totalTime)
      let displayText = String(format: "Distance: %.2fkm - Duration: \(displayTime)", totalDistance / 1000)

      cell.detailTextLabel?.text = displayText
    } else {
      cell.detailTextLabel?.text = nil
    }

    return cell
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

  private func stringFromTimeInterval(interval: Double) -> String {

    let hours = (Int(interval) / 3600)
    let minutes = Int(interval / 60) - Int(hours * 60)
    let seconds = Int(interval) - (Int(interval / 60) * 60)

    return String(format: "%0.2d:%0.2d:%0.2d",hours,minutes,seconds)
  }
}
