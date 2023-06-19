//
//  TurnByTurnInstructionsVC.swift
//  MapboxNavigation
//
//  Created by Santoso Pham on 6/19/23.
//  Copyright © 2023 Mapbox. All rights reserved.
//

import UIKit
import MapboxCoreNavigation
import MapboxMaps
import MapboxCoreMaps
import MapboxDirections

public protocol TurnByTurnInstructionsVCDelegate: AnyObject {
    func tapOnSteps()
}

public class TurnByTurnInstructionsVC: UIViewController {
    
    weak var titleLabel: UILabel!
    weak var separatorView: UIView!
    weak var tableView: UITableView!
    
    weak var delegate: TurnByTurnInstructionsVCDelegate?
    
    let cellId = "StepTableViewCellId"
    var routeProgress: RouteProgress!

    typealias StepSection = [RouteStep]
    var sections = [StepSection]()

    var previousLegIndex: Int = NSNotFound
    var previousStepIndex: Int = NSNotFound

    /**
     Initializes TurnByTurnInstructionsVC with a RouteProgress object.

     - parameter routeProgress: The user's current route progress.
     - seealso: RouteProgress
     */
    public convenience init(routeProgress: RouteProgress) {
        self.init()
        self.routeProgress = routeProgress
    }
    
    @discardableResult
    func rebuildDataSourceIfNecessary() -> Bool {
        let legIndex = routeProgress.legIndex
        let stepIndex = routeProgress.currentLegProgress.stepIndex
        let didProcessCurrentStep = previousLegIndex == legIndex && previousStepIndex == stepIndex

        guard !didProcessCurrentStep else { return false }

        sections.removeAll()

        let currentLeg = routeProgress.currentLeg

        // Add remaining steps for current leg
        var section = [RouteStep]()
        for (index, step) in currentLeg.steps.enumerated() {
            guard index > stepIndex else { continue }
            // Don't include the last step, it includes nothing
            guard index < currentLeg.steps.count - 1 else { continue }
            section.append(step)
        }

        if !section.isEmpty {
            sections.append(section)
        }

        // Include all steps on any future legs
        if !routeProgress.isFinalLeg {
            routeProgress.route.legs.suffix(from: routeProgress.legIndex + 1).forEach {
                var steps = $0.steps
                // Don't include the last step, it includes nothing
                _ = steps.popLast()
                sections.append(steps)
            }
        }

        previousStepIndex = stepIndex
        previousLegIndex = legIndex

        return true
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        rebuildDataSourceIfNecessary()

        NotificationCenter.default.addObserver(self, selector: #selector(progressDidChange(_:)), name: .routeControllerProgressDidChange, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .routeControllerProgressDidChange, object: nil)
    }

    @objc func progressDidChange(_ notification: Notification) {
        
        //  Need to get current progress and update
        guard let progress = notification.userInfo?[RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress else {return}
        routeProgress = progress
        
        if rebuildDataSourceIfNecessary() {
            tableView.reloadData()
        }
    }
    
    func setupViews() {
        
        //  Add tile
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Turn by Turn list"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = .darkText
        view.addSubview(label)
        self.titleLabel = label
        
        titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 8).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        titleLabel.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        //  Add separator
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.15)
        titleLabel.addSubview(separator)
        self.separatorView = separator
        
        separatorView.bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor).isActive = true
        separatorView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor).isActive = true
        separatorView.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor).isActive = true
        separatorView.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
        
        //  Add tableview
        let tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.separatorColor = .clear
        tableView.backgroundView = nil
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        self.tableView = tableView
        
        //  Layout
        tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        tableView.register(StepTableViewCell.self, forCellReuseIdentifier: cellId)
    }
}

extension TurnByTurnInstructionsVC: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let legIndex = indexPath.section
        let cell = tableView.cellForRow(at: indexPath) as! StepTableViewCell
        // Since as we progress, steps are removed from the list, we need to map the row the user tapped to the actual step on the leg.
        // If the user selects a step on future leg, all steps are going to be there.
        var stepIndex: Int
        if legIndex > 0 {
            stepIndex = indexPath.row
        } else {
            stepIndex = indexPath.row + routeProgress.currentLegProgress.stepIndex
            // For the current leg, we need to know the upcoming step.
            if sections[legIndex].indices.contains(indexPath.row) {
                stepIndex += 1
            }
        }
        
        guard routeProgress.route.containsStep(at: legIndex, stepIndex: stepIndex) else { return }
        delegate?.tapOnSteps()
    }
}

extension TurnByTurnInstructionsVC: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let steps = sections[section]
        return steps.count
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 96
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! StepTableViewCell
        return cell
    }

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        updateCell(cell as! StepTableViewCell, at: indexPath)
    }

    func updateCell(_ cell: StepTableViewCell, at indexPath: IndexPath) {
        cell.instructionsView.primaryLabel.viewForAvailableBoundsCalculation = cell
        cell.instructionsView.secondaryLabel.viewForAvailableBoundsCalculation = cell

        let step = sections[indexPath.section][indexPath.row]

        if let instructions = step.instructionsDisplayedAlongStep?.last {
            let fixedInstruction = fixInstruction(instructions)
            cell.instructionsView.update(for: fixedInstruction)
            cell.instructionsView.secondaryLabel.instruction = fixedInstruction.secondaryInstruction
        }
        cell.instructionsView.distance = step.distance

        cell.instructionsView.stepListIndicatorView.isHidden = true

        // Hide cell separator if it’s the last row in a section
        let isLastRowInSection = indexPath.row == sections[indexPath.section].count - 1
        cell.separatorView.isHidden = isLastRowInSection
    }

    func titleForHeader(in section: Int) -> String? {
        if section == 0 {
            return nil
        }

        let leg = routeProgress.route.legs[section]
        let sourceName = leg.source?.name
        let destinationName = leg.destination?.name
        let majorWays = leg.name.components(separatedBy: ", ")

        if let destinationName = destinationName?.nonEmptyString, majorWays.count > 1 {
            let summary = String.localizedStringWithFormat(NSLocalizedString("LEG_MAJOR_WAYS_FORMAT", bundle: .mapboxNavigation, value: "%@ and %@", comment: "Format for displaying the first two major ways"), majorWays[0], majorWays[1])
            return String.localizedStringWithFormat(NSLocalizedString("WAYPOINT_DESTINATION_VIA_WAYPOINTS_FORMAT", bundle: .mapboxNavigation, value: "%@, via %@", comment: "Format for displaying destination and intermediate waypoints; 1 = source ; 2 = destinations"), destinationName, summary)
        } else if let sourceName = sourceName?.nonEmptyString, let destinationName = destinationName?.nonEmptyString {
            return String.localizedStringWithFormat(NSLocalizedString("WAYPOINT_SOURCE_DESTINATION_FORMAT", bundle: .mapboxNavigation, value: "%@ and %@", comment: "Format for displaying start and endpoint for leg; 1 = source ; 2 = destination"), sourceName, destinationName)
        } else {
            return leg.name
        }
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return (section == 0) ? 0.0 : tableView.sectionHeaderHeight
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
}
