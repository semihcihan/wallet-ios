//  AmountViewController.swift

/*
	Package MobileWallet
	Created by Semih Cihan on 12.02.2020
	Using Swift 5.0
	Running on macOS 10.15

	Copyright 2019 The Tari Project

	Redistribution and use in source and binary forms, with or
	without modification, are permitted provided that the
	following conditions are met:

	1. Redistributions of source code must retain the above copyright notice,
	this list of conditions and the following disclaimer.

	2. Redistributions in binary form must reproduce the above
	copyright notice, this list of conditions and the following disclaimer in the
	documentation and/or other materials provided with the distribution.

	3. Neither the name of the copyright holder nor the names of
	its contributors may be used to endorse or promote products
	derived from this software without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
	CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
	INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
	OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
	DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
	CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
	SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
	NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
	HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
	OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import UIKit

class AmountViewController: UIViewController {

    var buttons = [UIButton]()
    let actionButton = SendButton(frame: .zero)
    let amountLabel = AnimatedBalanceLabel()
    let keypadContainerStackView = UIStackView()
    static let groupingSeparator: Character = "."
    let warningView = UIView()
    let warningLabel = UILabel()
    let warningBalanceLabel = UILabel()
    let valueImageView = UIImageView(image: Theme.shared.images.gemAmount)
    let transactionViewContainer = UIView()
    let animationDuration = 0.3
    var balanceCheckTimer: Timer?
    let transactionFeeLabel = UILabel()

    var rawInput = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = Theme.shared.colors.appBackground
        overrideUserInterfaceStyle = .light
        setup()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    deinit {
        balanceCheckTimer?.invalidate()
        balanceCheckTimer = nil
    }

    @objc private func checkAvailableBalance() {
        defer {
            balanceCheckTimer?.invalidate()
            balanceCheckTimer = nil
        }

        guard let transactionAmount = MicroTari.convertToNumber(rawInput) else {
            return
        }

        guard let wallet = TariLib.shared.tariWallet else {
            return
        }

        let (availableBalance, availableBalanceError) = wallet.availableBalance
        guard availableBalanceError == nil else {
            UserFeedback.shared.error(
                title: NSLocalizedString("Available Balance error", comment: "Amount screen"),
                description: NSLocalizedString("Failed to get the available balance.", comment: "Amount screen"),
                error: availableBalanceError
            )
            return
        }

        //TODO: add transaction amount
        if availableBalance < transactionAmount.int64Value {
            showBalanceExceeded(balance: String(availableBalance))
        }
        showTransactionAmount("15.75")
    }

    @objc private func keypadButtonTapped(_ sender: UIButton) {
        if sender.tag != 12 {
            let value: String = {
                if sender.tag < 10 {
                    return String(sender.tag)
                } else if sender.tag == 11 {
                    return "0"
                } else {
                    return String(AmountViewController.groupingSeparator)
                }
            }()

            addCharacater(value)
        } else {
            deleteCharacter()
        }
    }

    func deleteCharacter() {
        guard !rawInput.isEmpty else {
            return
        }

        let updatedInput = String(rawInput.dropLast())
        guard isValidNumber(string: updatedInput, finalNumber: false) else {
            return
        }

        rawInput = updatedInput
        updateLabelText()
    }

    func addCharacater(_ value: String) {
        let updatedText = rawInput + value

        guard isValidNumber(string: updatedText, finalNumber: false) else {
            return
        }

        rawInput = updatedText
        updateLabelText()
    }

    func updateLabelText() {
        let amountAttributedText = NSAttributedString(
            string: convertRawToFormattedString() ?? "",
            attributes: [
                NSAttributedString.Key.font: Theme.shared.fonts.amountLabel!,
                NSAttributedString.Key.foregroundColor: UIColor.black
            ]
        )

        amountLabel.attributedText = amountAttributedText

        hideBalanceExceeded()
        hideTransactionAmount()
        if balanceCheckTimer != nil {
            balanceCheckTimer?.invalidate()
        }
        if isValidNumber(string: rawInput, finalNumber: true) {
            balanceCheckTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(checkAvailableBalance), userInfo: nil, repeats: false)
        }
    }

    func isValidNumber(string: String, finalNumber: Bool) -> Bool {
        if !finalNumber && string.isEmpty {
            return true
        }

        guard string.first != "0" else {
            return false
        }

        guard string.filter({$0 == AmountViewController.groupingSeparator}).count < 2 else {
            return false
        }

        guard numberOfDecimals(in: string) <= MicroTari.ROUNDED_FRACTION_DIGITS else {
            return false
        }

        var str = string
        if !finalNumber && string.last == AmountViewController.groupingSeparator {
            str = String(str.dropLast())
        }

        return MicroTari.convertToNumber(str) != nil
    }

    func convertRawToFormattedString() -> String? {
        var decimalRemovedIfAtEndRawInput = rawInput
        var decimalRemoved = false
        if rawInput.last == AmountViewController.groupingSeparator {
            decimalRemovedIfAtEndRawInput = String(rawInput.dropLast())
            decimalRemoved = true
        }

        guard let number = MicroTari.convertToNumber(decimalRemovedIfAtEndRawInput) else {
            return nil
        }

        guard let formattedNumberString = MicroTari.convertToString(number, decimal: numberOfDecimals(in: decimalRemovedIfAtEndRawInput)) else {
            return nil
        }

        return formattedNumberString + (decimalRemoved ? MicroTari.decimalSeparator : "")
    }

    func numberOfDecimals(in string: String) -> Int {
        if let groupIndex = string.indexDistance(of: AmountViewController.groupingSeparator) {
            return max(string.count - groupIndex - 1, 0)
        }

        return 0
    }

    @objc func feeButtonPressed(_ sender: UIButton) {
        UserFeedback.shared.info(
            title: NSLocalizedString("Transaction Fee", comment: "Transaction detail view"),
            description: NSLocalizedString("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Maecenas consequat risus sit amet laoreet mollis. ", comment: "Transaction detail view"))
    }

    func showBalanceExceeded(balance: String) {
        warningBalanceLabel.text = balance
        warningView.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
        UIView.animate(withDuration: animationDuration, animations: { [weak self] in
            guard let self = self else {return}
            self.warningView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            self.warningView.isHidden = false
        }, completion: nil)

        valueImageView.transform = CGAffineTransform(translationX: 20, y: 0)
        amountLabel.transform = CGAffineTransform(translationX: 20, y: 0)
        UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 1, options: .curveEaseInOut, animations: { [weak self] in
            guard let self = self else {return}
            self.valueImageView.transform = CGAffineTransform.identity
            self.amountLabel.transform = CGAffineTransform.identity
        }, completion: nil)
    }

    func hideBalanceExceeded() {
        warningView.isHidden = true
    }

    func showTransactionAmount(_ amount: String) {
        transactionViewContainer.alpha = 0.0
        transactionFeeLabel.text = amount
        let moveAnimation: CATransition = CATransition()
        moveAnimation.timingFunction = CAMediaTimingFunction(name:
                CAMediaTimingFunctionName.easeIn)
        moveAnimation.type = CATransitionType.push
        moveAnimation.subtype = .fromTop
        moveAnimation.duration = animationDuration
        UIView.animate(withDuration: animationDuration) { [weak self] in
            guard let self = self else {return}
            self.transactionViewContainer.alpha = 1.0
            self.transactionViewContainer.layer.add(moveAnimation, forKey: CATransitionType.push.rawValue)
        }
    }

    func hideTransactionAmount() {
        transactionViewContainer.alpha = 0.0
    }
}

extension AmountViewController {
    func setup() {
        //contiue button
        view.addSubview(actionButton)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 25).isActive = true
        actionButton.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -25).isActive = true
        actionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10).isActive = true
        actionButton.setTitle(NSLocalizedString("Continue", comment: "Continue button on the amount screen"), for: .normal)
        actionButton.isEnabled = false
        setupKeypad()

        //amount label
        view.addSubview(amountLabel)
        amountLabel.animation = .update
        amountLabel.textAlignment = .center
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        amountLabel.rightAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.rightAnchor, constant: -8).isActive = true
        amountLabel.setContentHuggingPriority(.required, for: .horizontal)
        let amountTopLayoutGuide = UILayoutGuide()
        view.addLayoutGuide(amountTopLayoutGuide)
        amountTopLayoutGuide.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        amountTopLayoutGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        let amountBottomLayoutGuide = UILayoutGuide()
        view.addLayoutGuide(amountBottomLayoutGuide)
        amountBottomLayoutGuide.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        amountBottomLayoutGuide.bottomAnchor.constraint(equalTo: keypadContainerStackView.topAnchor).isActive = true
        amountBottomLayoutGuide.heightAnchor.constraint(equalTo: amountTopLayoutGuide.heightAnchor).isActive = true
        amountLabel.topAnchor.constraint(equalTo: amountTopLayoutGuide.bottomAnchor).isActive = true
        amountLabel.bottomAnchor.constraint(equalTo: amountBottomLayoutGuide.topAnchor).isActive = true
        amountLabel.heightAnchor.constraint(equalToConstant: 109).isActive = true
        let amountCenterXConstraint = amountLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        amountCenterXConstraint.priority = .defaultLow
        amountCenterXConstraint.isActive = true

        valueImageView.translatesAutoresizingMaskIntoConstraints = false
        valueImageView.widthAnchor.constraint(equalToConstant: 21).isActive = true
        view.addSubview(valueImageView)
        valueImageView.centerYAnchor.constraint(equalTo: amountLabel.centerYAnchor).isActive = true
        valueImageView.leftAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leftAnchor, constant: 8).isActive = true
        valueImageView.rightAnchor.constraint(equalTo: amountLabel.leftAnchor, constant: -16).isActive = true

        //warning view
        view.addSubview(warningView)
        warningView.isHidden = true
        warningView.translatesAutoresizingMaskIntoConstraints = false
        warningView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, constant: -50).isActive = true
        warningView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        warningView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 25).isActive = true
        warningView.layer.cornerRadius = 12
        warningView.layer.masksToBounds = true
        warningView.layer.borderWidth = 1
        warningView.layer.borderColor = Theme.shared.colors.amountWarning?.cgColor
        warningView.setContentCompressionResistancePriority(.required, for: .vertical)

        let warningStackView = UIStackView()
        warningView.addSubview(warningStackView)
        warningStackView.alignment = .center
        warningStackView.axis = .vertical
        warningStackView.spacing = 4
        warningStackView.translatesAutoresizingMaskIntoConstraints = false
        warningStackView.widthAnchor.constraint(equalTo: warningView.widthAnchor, constant: -24).isActive = true
        warningStackView.heightAnchor.constraint(equalTo: warningView.heightAnchor, constant: -24).isActive = true
        warningStackView.centerXAnchor.constraint(equalTo: warningView.centerXAnchor).isActive = true
        warningStackView.centerYAnchor.constraint(equalTo: warningView.centerYAnchor).isActive = true

        let warningBalanceStackView = UIStackView()
        warningBalanceStackView.alignment = .center
        warningStackView.addArrangedSubview(warningBalanceStackView)
        warningBalanceStackView.spacing = 4
        let warningBalanceIcon = UIImageView(image: Theme.shared.images.gemAmount?.withRenderingMode(.alwaysTemplate))
        warningBalanceIcon.translatesAutoresizingMaskIntoConstraints = false
        warningBalanceIcon.widthAnchor.constraint(equalToConstant: 11).isActive = true
        warningBalanceIcon.heightAnchor.constraint(equalToConstant: 11).isActive = true
        warningBalanceIcon.contentMode = .scaleAspectFit
        warningBalanceIcon.tintColor = Theme.shared.colors.amountWarning
        warningBalanceStackView.addArrangedSubview(warningBalanceIcon)
        warningBalanceStackView.addArrangedSubview(warningBalanceLabel)
        warningBalanceLabel.font = Theme.shared.fonts.warningBalanceLabel
        warningBalanceLabel.textColor = Theme.shared.colors.amountWarning

        warningStackView.addArrangedSubview(warningLabel)
        warningLabel.font = Theme.shared.fonts.amountWarningLabel
        warningLabel.textColor = Theme.shared.colors.amountWarningLabel
        warningLabel.text = NSLocalizedString("Not enough Tari in your available balance", comment: "Balance amount error")
        warningLabel.textAlignment = .center

        //transaction fee
        transactionViewContainer.alpha = 0.0
        view.addSubview(transactionViewContainer)
        transactionViewContainer.translatesAutoresizingMaskIntoConstraints = false
        transactionViewContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        transactionViewContainer.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 12).isActive = true
        let transactionStackView = UIStackView()
        transactionStackView.translatesAutoresizingMaskIntoConstraints = false
        transactionViewContainer.addSubview(transactionStackView)
        transactionStackView.leftAnchor.constraint(equalTo: transactionViewContainer.leftAnchor).isActive = true
        transactionStackView.rightAnchor.constraint(equalTo: transactionViewContainer.rightAnchor).isActive = true
        transactionStackView.topAnchor.constraint(equalTo: transactionViewContainer.topAnchor).isActive = true
        transactionStackView.bottomAnchor.constraint(equalTo: transactionViewContainer.bottomAnchor).isActive = true
        transactionStackView.alignment = .center
        transactionStackView.axis = .vertical

        transactionFeeLabel.translatesAutoresizingMaskIntoConstraints = false
        transactionFeeLabel.font = Theme.shared.fonts.transactionFeeLabel
        transactionFeeLabel.textColor = Theme.shared.colors.transactionViewValueLabel

        let feeButton = TextButton()
        feeButton.setTitle(NSLocalizedString("Transaction Fee", comment: "Transaction view screen"), for: .normal)
        feeButton.setRightImage(Theme.shared.images.transactionFee!)
        feeButton.addTarget(self, action: #selector(feeButtonPressed), for: .touchUpInside)

        transactionStackView.addArrangedSubview(transactionFeeLabel)
        transactionStackView.addArrangedSubview(feeButton)
    }

    func setupKeypad() {
        view.addSubview(keypadContainerStackView)
        keypadContainerStackView.translatesAutoresizingMaskIntoConstraints = false
        keypadContainerStackView.axis = .vertical
        keypadContainerStackView.distribution = .equalSpacing
        keypadContainerStackView.backgroundColor = .clear
        keypadContainerStackView.translatesAutoresizingMaskIntoConstraints = false
        keypadContainerStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        keypadContainerStackView.bottomAnchor.constraint(equalTo: actionButton.topAnchor, constant: -41).isActive = true
        keypadContainerStackView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        keypadContainerStackView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true

        let rows = [UIStackView(), UIStackView(), UIStackView(), UIStackView()]
        rows.forEach({
            $0.axis = .horizontal
            $0.distribution = .fillEqually
            keypadContainerStackView.addArrangedSubview($0)
        })

        for i in 0..<12 {
            let button = UIButton(type: .system)
            button.addTarget(self, action: #selector(keypadButtonTapped(_:)), for: .touchUpInside)
            button.tag = i + 1
            button.setTitleColor(Theme.shared.colors.keypadButton, for: .normal)
            button.titleLabel?.font = Theme.shared.fonts.keypadButton
            rows[i / (rows.count - 1)].addArrangedSubview(button)
            button.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor, multiplier: 0.1).isActive = true

            if i < 9 {
                button.setTitle("\(i + 1)", for: .normal)
            } else if i == 9 {
                button.setTitle(String(AmountViewController.groupingSeparator), for: .normal)
            } else if i == 10 {
                button.setTitle("0", for: .normal)
            } else if i == 11 {
                button.setTitle("x", for: .normal)
            }
        }
    }

}
