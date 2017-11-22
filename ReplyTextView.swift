//
//  ReplyTextView.swift
//  Memebox
//
//  Created by mememacpro on 2017. 11. 17..
//  Copyright © 2017년 memebox. All rights reserved.
//

import UIKit

class ReplyTextView: UIView, UIGestureRecognizerDelegate {
    var dimView: UIView?
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var placeholderLabel: UILabel!
    
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var modifyButton: UIButton!
    
    @IBOutlet weak var replyViewHeightLayoutConstraint: NSLayoutConstraint!
    
    fileprivate var initialSuperViewFrame: CGRect?
    fileprivate var keyboardHeight: CGFloat?
    
    class func create() -> ReplyTextView {
        return Bundle.main.loadNibNamed("ReplyTextView", owner: nil, options: nil)!.last as! ReplyTextView
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        initialize()
    }
    
    func initialize() {
        if let keyWindow = UIApplication.shared.keyWindow {
            let tap = UITapGestureRecognizer(target: self, action: #selector(ReplyTextView.hideDimView))
            tap.delegate = self
            
            let dv = UIView(frame: CGRect(x: 0, y: 0, width: MainScreen().width, height: MainScreen().height))
            dv.addGestureRecognizer(tap)
            dv.backgroundColor = .black
            dv.alpha = 0.25
            dv.isHidden = true
            dv.tag = 101
            
            self.dimView = dv
            keyWindow.addSubview(dv)
        }
        
        if let superView = self.superview {
            initialSuperViewFrame = superView.frame
        }
        
        textView.delegate = self
        textView.tintColor = UIColor(hexString: "ff5073")
        textView.isEditable = true
//        textView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
//        textView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
//        textView.textContainer.maximumNumberOfLines = 3
        
//        let style = NSMutableParagraphStyle()
//        style.lineSpacing = 20
//        textView.typingAttributes = [NSFontAttributeName: MBXFont.AppleSDGothicNeoLight(14.0), NSParagraphStyleAttributeName: style]
        
        placeholderLabel.isHidden = false
        
        cancelButton.isHidden = true
        modifyButton.isHidden = true
        
        if SessionManager.sharedManager.isLogined() {
            placeholderLabel.text = "댓글을 남겨주세요"
            
            saveButton.isHidden = false
            saveButton.isEnabled = false
            saveButton.alpha = 0.5
        } else {
            placeholderLabel.text = "로그인 후 댓글을 남겨주세요"
            
            saveButton.isHidden = true
        }
    }
    
    func viewWillAppear() {
        self.add(observer: self, name: NSNotification.Name.UIKeyboardWillShow.rawValue, target: #selector(self.keyboardWillChangeShow(_:)))
        self.add(observer: self, name: NSNotification.Name.UIKeyboardWillHide.rawValue, target: #selector(self.keyboardWillChangeHide(_:)))
    }
    
    func viewWillDisappear() {
        self.removeAll(observer: self)
    }
    
    func keyboardWillChangeShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        let keyboardFrame: CGRect = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? CGRect.zero
        let duration: TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        
        let curveNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
        let curveValue = curveNSN?.uintValue ?? UIViewAnimationOptions.curveEaseIn.rawValue
        let curve: UIViewAnimationOptions = UIViewAnimationOptions(rawValue: curveValue)
        
        if let superView = self.superview, let initFrame = self.initialSuperViewFrame {
            UIView.animate(withDuration: duration, delay: 0, options: curve, animations: {
                superView.frame = CGRect(x: initFrame.origin.x, y: initFrame.origin.y,
                                         width: initFrame.size.width, height: initFrame.size.height - keyboardFrame.height)
                self.showDimView(height: initFrame.size.height - keyboardFrame.height - self.frame.height)
            }, completion: nil)
        }
        
        self.keyboardHeight = keyboardFrame.height
    }
    
    func keyboardWillChangeHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        let duration: TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        
        let curveNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
        let curveValue = curveNSN?.uintValue ?? UIViewAnimationOptions.curveEaseIn.rawValue
        let curve: UIViewAnimationOptions = UIViewAnimationOptions(rawValue: curveValue)
        
        if let superView = self.superview, let initFrame = self.initialSuperViewFrame {
            UIView.animate(withDuration: duration, delay: 0, options: curve, animations: {
                superView.frame = initFrame
                self.hideDimView()
            }, completion: nil)
        }
    }
    
    func showDimView(height: CGFloat) {
        guard let dimView = self.dimView else { return }
        dimView.isHidden = false
        
        dimView.frame = CGRect(x: 0, y: 0, width: MainScreen().width, height: height)
    }
    
    func hideDimView() {
        guard let dimView = self.dimView else { return }
        dimView.frame = CGRect(x: 0, y: 0, width: MainScreen().width, height: MainScreen().height)
        dimView.isHidden = true
        
        textView.resignFirstResponder()
    }
}

extension ReplyTextView: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.becomeFirstResponder()
        placeholderLabel.isHidden = true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        guard let totalStr = textView.text, let dimView = self.dimView, let keyboardHeight = self.keyboardHeight else { return }
        
        if totalStr == "" {
            placeholderLabel.isHidden = false
            
            saveButton.isEnabled = false
            saveButton.alpha = 0.5
            return
        } else {
            placeholderLabel.isHidden = true
            
            saveButton.isEnabled = true
            saveButton.alpha = 1
        }
        
        let lineHeight: CGFloat = 20
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.minimumLineHeight = lineHeight
        let attrStr = NSAttributedString(string: totalStr, attributes: [NSFontAttributeName: MBXFont.AppleSDGothicNeoLight(14.0), NSParagraphStyleAttributeName: paraStyle])
    
        let attrStrLine = attrStr.heightWithConstrainedWidth(textView.frame.width - 10) / lineHeight
        
        switch attrStrLine {
        case 1:
            replyViewHeightLayoutConstraint.constant = 45
            dimView.frame = CGRect(x: 0, y: 0, width: MainScreen().width, height: MainScreen().height - keyboardHeight - 45)
        case 2:
            replyViewHeightLayoutConstraint.constant = 65
            dimView.frame = CGRect(x: 0, y: 0, width: MainScreen().width, height: MainScreen().height - keyboardHeight - 65)
        default:
            replyViewHeightLayoutConstraint.constant = 85
            dimView.frame = CGRect(x: 0, y: 0, width: MainScreen().width, height: MainScreen().height - keyboardHeight - 85)
        }
    }
}
