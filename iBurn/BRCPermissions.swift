//
//  BRCPermissions.swift
//  iBurn
//
//  Created by Christopher Ballinger on 8/14/15.
//  Copyright (c) 2015 Burning Man Earth. All rights reserved.
//

import UIKit
import PermissionScope

/** Wrapper around swift-only PermissionScope */
public class BRCPermissions: NSObject {
    
    /** Show location permissions prompt */
    public static func promptForLocation(completion: dispatch_block_t) {
        let pscope = PermissionScope()
        pscope.headerLabel.text = "Location"
        pscope.bodyLabel.text = "iBurn is best with location!"
        
        pscope.addPermission(LocationWhileInUsePermission(), message: "Seriously, it's the way to go.")
        pscope.show({ (finished, results) -> Void in
            completion()
            print("got results \(results)")
        }) { (results) -> Void in
            print("thing was cancelled")
        }
    }
    
    public static func promptForEvents(completion: dispatch_block_t) {
        let pscope = PermissionScope()
        pscope.headerLabel.text = "Reminders"
        pscope.bodyLabel.text = "Don't you want reminders?"
        pscope.addPermission(EventsPermission(), message: "You can see your favorited events in the Calendar app.")
        pscope.show({ (finished, results) -> Void in
            print("got results \(results)")
            completion()
        }) { (results) -> Void in
            print("thing was cancelled")
        }
    }
    
    /** Show notification permissions prompt */
    public static func promptForPush(completion: dispatch_block_t) {
        let pscope = PermissionScope()
        pscope.headerLabel.text = "Reminders"
        pscope.bodyLabel.text = "Don't you want reminders?"
        pscope.addPermission(NotificationsPermission(), message: "Don't forget to live in the moment.")
        pscope.addPermission(EventsPermission(), message: "You can see your favorited events in the Calendar app.")
        pscope.show({ (finished, results) -> Void in
            print("got results \(results)")
            completion()
            }) { (results) -> Void in
            print("thing was cancelled")
        }
    }
}
