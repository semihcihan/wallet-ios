//  WalletCallbacks.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2019/11/26
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

import Foundation

public func globaCallback(completedTransactionPointer: OpaquePointer?) {
    print(">>>>>>>>>>>>>>>>>GLOBAL<<<<<<<<<<<<<<<<<<<<")
    print(completedTransactionPointer as Any)
    fatalError("This crash is a good thing...")
}

extension Wallet {
    func registerTransactionBroadcastCallback(callback: (_ completedTransaction: CompletedTransaction) -> Void) throws {
        
        //MARK: -- Registering the callback using a closure
//        let didRegisterCallback = wallet_callback_register_mined(self.pointer, { (completedTransactionPointer: OpaquePointer?) -> Void in
//            print(">>>>>>>>>>>>>>>>>CLOSURE<<<<<<<<<<<<<<<<<<<<")
//            print(completedTransactionPointer as Any)
//            fatalError("This crash is a good thing...")
//        })

        //MARK: -- Registering the callback using a reference to a global function
        let funcPointer: (@convention(c) (OpaquePointer?) -> Void)! = globaCallback
        let didRegisterCallback = wallet_callback_register_mined(self.pointer, funcPointer)

        print("Registered>>>")
        print(didRegisterCallback)

        if !didRegisterCallback {
            throw WalletErrors.failedToRegisterCallback
        }
    }

    func addCallback() {
        do {
            try self.registerTransactionBroadcastCallback(callback: { (completedTransaction) in
                print(completedTransaction.status)
            })
        } catch {
            fatalError(error.localizedDescription)
        }

    }
}
