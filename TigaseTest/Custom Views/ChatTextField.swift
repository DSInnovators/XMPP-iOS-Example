//
//  ChatTextField.swift
//  TigaseTest
//
//  Created by Abid Rahman on 11/6/20.
//  Copyright © 2020 Abid Rahman. All rights reserved.
//

import UIKit

protocol ChatTextFieldDelegate {
    func didStartTyping()
    func didEndTyping()
}

class ChatTextField: UITextField {
    private var timer: Timer?
    private var timerDelayForDetectingEndOfTyping: TimeInterval = 2

    private var isTyping: Bool = false

    public var chatTextFieldDelegate: ChatTextFieldDelegate?

    required override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }

    private func setup() {
        self.addTarget(self, action: #selector(self.textFieldDidChange), for: .editingChanged)
    }

    @objc private func textFieldDidChange() {
        if !self.isTyping {
            self.chatTextFieldDelegate?.didStartTyping()
            self.isTyping = true
        }

        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: self.timerDelayForDetectingEndOfTyping, repeats: false, block: { [weak self] (timer) in
            self?.isTyping = false
            self?.chatTextFieldDelegate?.didEndTyping()
        })
    }
}
