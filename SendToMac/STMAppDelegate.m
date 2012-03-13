//
//  STMAppDelegate.m
//  SendToMac
//
//  Created by Maarten Billemont on 12/03/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "STMAppDelegate.h"

#import <netinet/in.h>
#import <sys/socket.h>

@interface STMAppDelegate ()

@property (readwrite, strong, nonatomic) NSNetService                   *netService;
@property (readwrite, assign, nonatomic) CFSocketRef                    listeningSocket;

- (void)connectionEstablishedOnHandle:(CFSocketNativeHandle)handle;

@end

@implementation STMAppDelegate
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize netService, listeningSocket;

@synthesize statusItem, preferenceTabs;
@synthesize aboutPreferenceTab, devicesPreferenceTab;

+ (STMAppDelegate *)get {
    
    return (STMAppDelegate *)[NSApplication sharedApplication].delegate;
}

+ (NSManagedObjectContext *)managedObjectContext {
    
    return [[self get] managedObjectContext];
}

+ (NSManagedObjectModel *)managedObjectModel {
    
    return [[self get] managedObjectModel];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    self.statusItem.title = @"STM";
    
    [self setupNetworkListener];
}

#pragma mark - Network

static void ListeningSocketCallback(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
    
    [[STMAppDelegate get] connectionEstablishedOnHandle:*(const CFSocketNativeHandle *)data];
}

- (void)setupNetworkListener {
    
    struct sockaddr_in6 serverAddress6;
    socklen_t serverAddress6_len    = sizeof(serverAddress6);
    memset(&serverAddress6, 0, serverAddress6_len);
    serverAddress6.sin6_len         = serverAddress6_len;
    serverAddress6.sin6_family      = AF_INET6;
    
    NSSocketNativeHandle socketHandle;
    if (0 > (socketHandle = socket(AF_INET6, SOCK_STREAM, 0))) {
        err(@"Couldn't create socket: %@", errstr());
        return;
    }
    if (0 > bind(socketHandle, (const struct sockaddr *) &serverAddress6, serverAddress6_len)) {
        err(@"Couldn't bind socket: %@", errstr());
        close(socketHandle);
        return;
    }
    if (0 > getsockname(socketHandle, (struct sockaddr *) &serverAddress6, &serverAddress6_len)) {
        err(@"Couldn't get socket info: %@", errstr());
        close(socketHandle);
        return;
    }
    if (0 > listen(socketHandle, 5)) {
        err(@"Couldn't get socket info: %@", errstr());
        close(socketHandle);
        return;
    }
    if (!(self.listeningSocket = CFSocketCreateWithNative(NULL, socketHandle, kCFSocketAcceptCallBack, ListeningSocketCallback, NULL))) {
        err(@"Couldn't start listening on the socket: %@", errstr());
        return;
    }
    
    CFRunLoopSourceRef runLoopSource = CFSocketCreateRunLoopSource(NULL, self.listeningSocket, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopDefaultMode);
    CFRelease(runLoopSource);
    
    int chosenPort = ntohs(serverAddress6.sin6_port);
    inf(@"Bound to port %d", chosenPort);
    self.netService = [[NSNetService alloc] initWithDomain:@"" type:@"_sendtomac._tcp." name:@"Send-To-Mac" port:chosenPort];
    if(!self.netService) {
        err(@"Couldn't initialize the Bonjour service.");
        return;
    }
    
    self.netService.delegate = self;
    [self.netService publish];
}

- (void)connectionEstablishedOnHandle:(CFSocketNativeHandle)handle {
    
    dbg(@"%@%d", NSStringFromSelector(_cmd), handle);
}

/* Sent to the NSNetService instance's delegate prior to advertising the service on the network. If for some reason the service cannot be published, the delegate will not receive this message, and an error will be delivered to the delegate via the delegate's -netService:didNotPublish: method.
 */
- (void)netServiceWillPublish:(NSNetService *)sender {
    
    dbg(@"%@", NSStringFromSelector(_cmd));
}

/* Sent to the NSNetService instance's delegate when the publication of the instance is complete and successful.
 */
- (void)netServiceDidPublish:(NSNetService *)sender {
    
    dbg(@"%@", NSStringFromSelector(_cmd));
}

/* Sent to the NSNetService instance's delegate when an error in publishing the instance occurs. The error dictionary will contain two key/value pairs representing the error domain and code (see the NSNetServicesError enumeration above for error code constants). It is possible for an error to occur after a successful publication.
 */
- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict {
    
    dbg(@"%@%@", NSStringFromSelector(_cmd), errorDict);
}

/* Sent to the NSNetService instance's delegate prior to resolving a service on the network. If for some reason the resolution cannot occur, the delegate will not receive this message, and an error will be delivered to the delegate via the delegate's -netService:didNotResolve: method.
 */
- (void)netServiceWillResolve:(NSNetService *)sender {
    
    dbg(@"%@", NSStringFromSelector(_cmd));
}

/* Sent to the NSNetService instance's delegate when one or more addresses have been resolved for an NSNetService instance. Some NSNetService methods will return different results before and after a successful resolution. An NSNetService instance may get resolved more than once; truly robust clients may wish to resolve again after an error, or to resolve more than once.
 */
- (void)netServiceDidResolveAddress:(NSNetService *)sender {
    
    dbg(@"%@", NSStringFromSelector(_cmd));
}

/* Sent to the NSNetService instance's delegate when an error in resolving the instance occurs. The error dictionary will contain two key/value pairs representing the error domain and code (see the NSNetServicesError enumeration above for error code constants).
 */
- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
    
    dbg(@"%@%@", NSStringFromSelector(_cmd), errorDict);
}

/* Sent to the NSNetService instance's delegate when the instance's previously running publication or resolution request has stopped.
 */
- (void)netServiceDidStop:(NSNetService *)sender {
    
    dbg(@"%@", NSStringFromSelector(_cmd));
}

/* Sent to the NSNetService instance's delegate when the instance is being monitored and the instance's TXT record has been updated. The new record is contained in the data parameter.
 */
- (void)netService:(NSNetService *)sender didUpdateTXTRecordData:(NSData *)data {
    
    dbg(@"%@%@", NSStringFromSelector(_cmd), data);
}

#pragma mark - Core Data stack

- (NSURL *)applicationFilesDirectory {
    
    NSURL *appSupportURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *applicationFilesDirectory = [appSupportURL URLByAppendingPathComponent:@"com.lyndir.lhunath.SendToMac"];
    
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtURL:applicationFilesDirectory withIntermediateDirectories:YES attributes:nil error:&error];
    if (error)
        [[NSApplication sharedApplication] presentError:error];
    
    return applicationFilesDirectory;
}

- (NSManagedObjectModel *)managedObjectModel {
    
    if (__managedObjectModel)
        return __managedObjectModel;
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"SendToMac" withExtension:@"momd"];
    return __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
}

- (NSManagedObjectContext *)managedObjectContext {
    
    if (__managedObjectContext)
        return __managedObjectContext;
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator) {
        __managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        __managedObjectContext.persistentStoreCoordinator = coordinator;
    }
    
    return __managedObjectContext;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    
    if (__persistentStoreCoordinator)
        return __persistentStoreCoordinator;
    
    NSURL *storeURL = [[self applicationFilesDirectory] URLByAppendingPathComponent:@"SendToMac.sqlite"];
    
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    [__persistentStoreCoordinator lock];
    NSError *error = nil;
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL
                                                          options:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                   [NSNumber numberWithBool:YES],   NSInferMappingModelAutomaticallyOption,
                                                                   [NSNumber numberWithBool:YES],   NSMigratePersistentStoresAutomaticallyOption,
                                                                   nil]
                                                            error:&error]) {
        err(@"Unresolved error %@, %@", error, [error userInfo]);
#if DEBUG
        wrn(@"Deleted datastore: %@", storeURL);
        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];        
#endif
        
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    [__persistentStoreCoordinator unlock];
    
    return __persistentStoreCoordinator;
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    
    return [[self managedObjectContext] undoManager];
}

#pragma mark - Actions

- (IBAction)activatePreferenceTab:(NSToolbarItem *)sender {
    
    if (sender == self.aboutPreferenceTab)
        [self.preferenceTabs selectTabViewItemWithIdentifier:@"about"];
    else if (sender == self.devicesPreferenceTab)
        [self.preferenceTabs selectTabViewItemWithIdentifier:@"devices"];
}

@end
