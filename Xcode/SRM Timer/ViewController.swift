//
//  ViewController.swift
//  SRM Timer
//
//  Created by Alexandru Rosianu on 21/08/14.
//  Copyright (c) 2014 Alexandru Rosianu. All rights reserved.
//

import UIKit
import QuartzCore

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITableViewDataSource {
    
    // Arrays of tips displayed when the app is opened
    let tips = [
        "SRM Timer helps you track your\nprogress while practicing for\nSingle Round Matches.",
        "Use it every day and you’ll be\na winner in no time :)",
        "Press the Start button, come on!\nI know you want to."
    ]
    
    // The available languages from which users can choose from
    let languages = [
        "JavaScript",
        "Objective-C",
        "Swift",
        "C++",
        "C",
        "C#",
        "Java",
        "Python",
        "Ruby",
        "PHP",
        "HTML5",
        "CSS"
    ]
    
    // Some colour constants
    let lightColour = UIColor(red: 198/255.0, green: 68/255.0, blue: 252/255.0, alpha: 1.0)
    let placeholderColour = UIColor(red: 88/255.0, green: 86/255.0, blue: 214/255.0, alpha: 0.75)
    let darkColour = UIColor(red: 88/255.0, green: 86/255.0, blue: 214/255.0, alpha: 1.0)
    let transparentColour = UIColor(white: 0.0, alpha: 0.0)
    
    // View tags
    let problemFieldTag = 100
    let divisionControlTag = 101
    let languagePickerTag = 102
    let cellTimeLabelTag = 110
    
    // Outlets
    @IBOutlet weak var appNameLabel: UILabel!
    @IBOutlet weak var previousProblemsLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    
    @IBOutlet weak var hTime: UILabel!
    @IBOutlet weak var hSymbol: UILabel!
    @IBOutlet weak var mTime: UILabel!
    @IBOutlet weak var mSymbol: UILabel!
    @IBOutlet weak var sTime: UILabel!
    @IBOutlet weak var sSymbol: UILabel!
    
    // Used to show the sliding tips
    var tipLabel: UILabel?
    var tipLabelNew: UILabel?
    var lastTip = -1
    
    // Track many seconds the user has practiced for
    var secondsElapsed = 0
    
    // Timers used for sliding the tips and tracking practice time, respectively
    var tipTimer: NSTimer?
    var practiceTimer: NSTimer?
    
    // Store practice times
    struct Record {
        let name: String
        let division: Int
        let language: String
        let time: Int
    }
    
    var records = [Record]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the datasource for the tableView
        self.tableView.dataSource = self
        
        // Initial set-up
        setGradient()
        switchText()
        
        // Create a timer to slide tips
        tipTimer = NSTimer.scheduledTimerWithTimeInterval(4, target: self, selector: "switchText", userInfo: nil, repeats: true)
    }
    
    // Action for clicks on the Start button
    @IBAction func started() {
        // Stop showing tips
        tipTimer?.invalidate()
        
        // Move these 2 buttons lower for a nicer animation effect
        stopButton.frame.origin.y = 538
        pauseButton.frame.origin.y = 538
        
        self.view.layoutIfNeeded()
        
        // Start animating views – hide, show, move
        UIView.animateWithDuration(0.75, animations: {
            self.stopButton.alpha = 1
            self.pauseButton.alpha = 1
            self.startButton.alpha = 0
            
            self.appNameLabel.alpha = 0
            
            if self.records.count == 0 {
                self.previousProblemsLabel.alpha = 0.8
            }
            
            self.tipLabel?.alpha = 0
            self.tipLabelNew?.alpha = 0
            
            self.hTime.alpha = 1
            self.mTime.alpha = 1
            self.sTime.alpha = 1
            
            self.hSymbol.alpha = 1
            self.mSymbol.alpha = 1
            self.sSymbol.alpha = 1
            
            self.appNameLabel.frame.origin.y = 65
            self.stopButton.frame.origin.y = 438
            self.pauseButton.frame.origin.y = 438
            
            self.view.layoutIfNeeded()
        }, { (Bool) -> Void in
            self.tipLabel = nil
            self.tipLabelNew = nil
            
            // Start the timer to track practice time
            self.startPracticeTimer()
        })
    }
    
    // Action for clicks on the Stop button
    @IBAction func stopped() {
        // Pause the timer which tracks practice time
        stopPracticeTimer()
        
        // Build the dialog
        let dialog = CustomIOS7AlertView()
        dialog.buttonTitles = ["Dismiss", "Add"]
        dialog.containerView = createDialogView()
        
        // Remove previous delegate and assign a custom click listener
        dialog.delegate = nil
        dialog.onButtonTouchUpInside = dialogButtonPressed
        
        // Set colours
        dialog.buttonColor = UIColor(red:88/255, green: 86/255, blue: 214/255, alpha: 1)
        dialog.buttonColorHighlighted = UIColor(red:198/255, green: 68/255, blue: 252/255, alpha: 1)
        
        dialog.show()
    }
    
    // Handle presses on the dialog buttons
    func dialogButtonPressed(dialog: CustomIOS7AlertView!, buttonIndex: Int) {
        // If the button is "Add"
        if buttonIndex == 1 {
            // Add a new record
            self.records.append(Record(
                name: (dialog.containerView.viewWithTag(problemFieldTag) as UITextField).text,
                division: (dialog.containerView.viewWithTag(divisionControlTag) as UISegmentedControl).selectedSegmentIndex + 1,
                language: languages[(dialog.containerView.viewWithTag(languagePickerTag) as UIPickerView).selectedRowInComponent(0)],
                time: self.secondsElapsed
            ))
            
            // Update the table
            self.tableView.beginUpdates()
            self.tableView.insertRowsAtIndexPaths(
                [NSIndexPath(forRow: self.records.count - 1, inSection: 0)],
                withRowAnimation: UITableViewRowAnimation.Automatic)
            self.tableView.endUpdates()
            
            // Scroll to the last item
            self.tableView.scrollToRowAtIndexPath(
                NSIndexPath(forRow: self.records.count - 1, inSection: 0),
                atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
        }
        
        dialog.close()
        
        // Reset time
        self.secondsElapsed = 0
        self.updateDisplayedTime()
        
        // Move the app name label to its position
        self.view.layoutIfNeeded()
        self.appNameLabel.frame.origin.y = 65
        self.view.layoutIfNeeded()
        
        // Animate views
        UIView.animateWithDuration(0.75, animations: {
            self.stopButton.alpha = 0
            self.pauseButton.alpha = 0
            self.startButton.alpha = 1
            
            self.appNameLabel.alpha = 1
            
            self.hTime.alpha = 0
            self.mTime.alpha = 0
            self.sTime.alpha = 0
            
            self.hSymbol.alpha = 0
            self.mSymbol.alpha = 0
            self.sSymbol.alpha = 0
            
            if self.records.count > 0 {
                self.previousProblemsLabel.alpha = 0
                self.tableView.alpha = 1
            }
            
            self.startButton.frame.origin.y = 438
            self.stopButton.frame.origin.y = 538
            self.pauseButton.frame.origin.y = 538
            
            self.view.layoutIfNeeded()
        })
    }
    
    // Action for clicks on both the Pause and the Resume buttons
    @IBAction func paused() {
        if let timerIsValid = practiceTimer?.valid {
            if timerIsValid {
                stopPracticeTimer()
                pauseButton.setImage(UIImage(named: "resumeButton"), forState: UIControlState.Normal)
            } else {
                startPracticeTimer()
                pauseButton.setImage(UIImage(named: "pauseButton"), forState: UIControlState.Normal)
            }
        }
    }
    
    // Creates the views to be displayed in the dialog
    func createDialogView() -> UIView {
        let dialogView = UIView(frame: CGRectMake(0, 0, 300, 300))
        
        let titleLabel = UILabel(frame: CGRectMake(0, 0, 270, 30))
        titleLabel.center = CGPoint(x: dialogView.frame.width / 2, y: 33)
        titleLabel.textAlignment = NSTextAlignment.Center
        titleLabel.textColor = darkColour
        titleLabel.font = UIFont.boldSystemFontOfSize(17)
        titleLabel.text = "What did you just practice?"
        
        let problemField = UITextField(frame: CGRectMake(15, 66, 270, 40))
        problemField.attributedPlaceholder = NSAttributedString(string: "Problem name", attributes: [NSForegroundColorAttributeName: placeholderColour])
        problemField.layer.borderColor = darkColour.CGColor!
        problemField.layer.borderWidth = 1.2
        problemField.layer.cornerRadius = 5
        problemField.backgroundColor = transparentColour
        problemField.textColor = darkColour
        problemField.tag = problemFieldTag
        
        let paddingView = UIView(frame: CGRectMake(0, 0, 10, problemField.frame.height))
        problemField.leftView = paddingView
        problemField.leftViewMode = UITextFieldViewMode.Always
        
        let divisionControl = UISegmentedControl(frame: CGRectMake(15, 116, 270, 40))
        divisionControl.insertSegmentWithTitle("Division I", atIndex: 0, animated: false)
        divisionControl.insertSegmentWithTitle("Division II", atIndex: 1, animated: false)
        divisionControl.tintColor = darkColour
        divisionControl.tag = divisionControlTag
        
        let languagePicker = UIPickerView(frame: CGRectMake(15, 146, 270, 80))
        languagePicker.delegate = self
        languagePicker.dataSource = self
        languagePicker.tag = languagePickerTag
        languagePicker.selectRow(2, inComponent: 0, animated: false)
        
        dialogView.addSubview(titleLabel)
        dialogView.addSubview(problemField)
        dialogView.addSubview(languagePicker)
        dialogView.addSubview(divisionControl)
        
        return dialogView
    }
    
    // TableView: Return the number of rows
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        return records.count
    }

    // TableView: Return the cell for the given row index
    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        let record = records[indexPath.row]
        let cellIdentifier = "cell"
        
        var cell: UITableViewCell? = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as? UITableViewCell
        
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: cellIdentifier)
            cell!.frame = CGRectMake(0, 0, tableView.frame.width, tableView.rowHeight)
            cell!.backgroundColor = transparentColour
            
            let timeLabel = UILabel(frame: CGRectMake(183, 23, 100, 27))
            timeLabel.textAlignment = NSTextAlignment.Right
            timeLabel.textColor = UIColor.whiteColor()
            timeLabel.font = cell!.detailTextLabel.font
            timeLabel.tag = cellTimeLabelTag
            
            cell!.contentView.addSubview(timeLabel)
        }
        
        cell!.imageView.image = UIImage(named: "division\(record.division)")
        
        cell!.textLabel.textColor = UIColor.whiteColor()
        cell!.textLabel.text = record.name
        
        cell!.detailTextLabel.textColor = UIColor.whiteColor()
        cell!.detailTextLabel.text = record.language
        
        let timeLabel = cell!.contentView.viewWithTag(cellTimeLabelTag) as UILabel
        timeLabel.text = getTimeString(record.time)
        
        return cell
    }
    
    // PickerView: Returns the number of components in the pickerView
    func numberOfComponentsInPickerView(pickerView: UIPickerView!) -> Int {
        return 1
    }
    
    // PickerView: Returns the number of items (languages)
    func pickerView(pickerView: UIPickerView!, numberOfRowsInComponent component: Int) -> Int {
        return languages.count
    }
    
    // PickerView: Returns the language for the given row index
    func pickerView(pickerView: UIPickerView!, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString! {
        return NSAttributedString(string: languages[row], attributes: [NSForegroundColorAttributeName: darkColour])
    }
    
    // Converts the time given in seconds to '<HH>h <MM>m <SS>s'
    func getTimeString(secondsElapsed: Int) -> String {
        var seconds = secondsElapsed
        
        let hours = seconds >= 3600 ? (seconds - seconds % 3600) / 3600 : 0
        seconds -= hours * 3600
        
        let minutes = seconds >= 60 ? (seconds - seconds % 60) / 60 : 0
        seconds -= minutes * 60
        
        return "\(ensureLeadingZero(hours))h \(ensureLeadingZero(minutes))m \(ensureLeadingZero(seconds))s"
    }
    
    // Update the labels that display the elapsed time so far
    func updateDisplayedTime() {
        var seconds = secondsElapsed
        
        let hours = seconds >= 3600 ? (seconds - seconds % 3600) / 3600 : 0
        seconds -= hours * 3600
        
        let minutes = seconds >= 60 ? (seconds - seconds % 60) / 60 : 0
        seconds -= minutes * 60
        
        hTime.text = ensureLeadingZero(hours)
        mTime.text = ensureLeadingZero(minutes)
        sTime.text = ensureLeadingZero(seconds)
    }
    
    // Convert the given int to string so that it always has 2 digits
    func ensureLeadingZero(no: Int) -> String {
        var leading = ""
        
        if no < 10 {
            leading = "0"
        }
        
        return "\(leading)\(no)"
    }

    // Start the timer that tracks practice time
    func startPracticeTimer() {
        practiceTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "practiceTimerTick", userInfo: nil, repeats: true)
    }
    
    // Stop the timer that tracks practice time
    func stopPracticeTimer() {
        practiceTimer?.invalidate()
    }
    
    // Called every 1 second while the practice timer is running
    func practiceTimerTick() {
        secondsElapsed++;
        updateDisplayedTime()
    }
    
    // Slide out the currently displayed tip and slide in the next one
    func switchText() {
        self.tipLabelNew = UILabel(frame: CGRect(x: 0, y: 0, width: 540, height: 108))
        self.tipLabelNew!.center = CGPointMake(self.view.frame.width / 2 + self.tipLabelNew!.frame.width, self.view.frame.height / 2 - 20)
        self.tipLabelNew!.textAlignment = NSTextAlignment.Center
        self.tipLabelNew!.textColor = UIColor.whiteColor()
        self.tipLabelNew!.numberOfLines = 3
        self.tipLabelNew!.text = nextText()
        
        self.view.addSubview(self.tipLabelNew!)
        self.view.layoutIfNeeded()
        
        UIView.animateWithDuration(1, animations: {
            self.tipLabel?.frame.origin.x -= self.tipLabel!.frame.width
            self.tipLabelNew!.frame.origin.x -= self.tipLabelNew!.frame.width
            
            self.view.layoutIfNeeded()
        }, completion: { (Bool) -> Void in
            self.tipLabel = self.tipLabelNew
        })
    }
    
    // Returns the next tip that should be displayed
    func nextText() -> String {
        lastTip++
        
        if lastTip >= tips.count {
            lastTip = 0
        }
        
        return tips[lastTip]
    }
    
    // Set a nice gradient as the app's background
    func setGradient() {
        let colorTop = lightColour
        let colorBottom = darkColour
        
        let layer = CAGradientLayer()
        layer.colors = [colorTop.CGColor!, colorBottom.CGColor!]
        layer.locations = [0.0, 1.0];
        layer.frame = self.view.bounds
        
        self.view.layer.insertSublayer(layer, atIndex: 0)
    }
    
}
