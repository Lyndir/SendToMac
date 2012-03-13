//
//  STMAppDelegate.h
//  SendToMac
//
//  Created by Maarten Billemont on 12/03/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface STMAppDelegate : NSObject <NSApplicationDelegate, NSNetServiceDelegate, NSNetServiceBrowserDelegate>

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator    *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel            *managedObjectModel;
@property (readonly, strong, nonatomic) IBOutlet NSManagedObjectContext          *managedObjectContext;

@property (readonly, strong, nonatomic) NSNetService                    *netService;

@property (strong) NSStatusItem                                         *statusItem;
@property (weak) IBOutlet NSToolbarItem                                 *aboutPreferenceTab;
@property (weak) IBOutlet NSToolbarItem                                 *devicesPreferenceTab;
@property (weak) IBOutlet NSTabView                                     *preferenceTabs;

+ (STMAppDelegate *)get;
+ (NSManagedObjectModel *)managedObjectModel;
+ (NSManagedObjectContext *)managedObjectContext;

- (IBAction)activatePreferenceTab:(NSToolbarItem *)sender;

@end
