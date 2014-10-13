//
//  BLEBroadcaster.m
//  BLEMeshChat
//
//  Created by Christopher Ballinger on 10/10/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "BLEBroadcaster.h"

static NSString * const kBLEBroadcasterRestoreIdentifier = @"kBLEBroadcasterRestoreIdentifier";

static NSString * const kBLEMeshChatServiceUUIDString = @"96F22BCA-F08C-43F9-BF7D-EEBC579C94D2";
static NSString * const kBLEMeshChatReadCharacteristicUUIDString = @"21C7DE8E-B0D0-4A41-9B22-78221277E2AA";
static NSString * const kBLEMeshChatIdentityCharacteristicUUIDString = @"63D14BAD-ABDE-44BC-BFCC-453AE2C8D2C8";

@interface BLEBroadcaster()
@property (nonatomic, strong) CBPeripheralManager *peripheralManager;
@property (nonatomic, strong) CBMutableService *meshChatService;
@property (nonatomic, strong) CBMutableCharacteristic *readCharacteristic;
@property (nonatomic, strong) CBMutableCharacteristic *identityCharacteristic;
@property (nonatomic) dispatch_queue_t eventQueue;
@end

@implementation BLEBroadcaster

- (instancetype) init {
    if (self = [super init]) {
        _eventQueue = dispatch_queue_create("BLEBroadcaster Event Queue", 0);
        _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self
                                                                     queue:_eventQueue
                                                                   options:@{CBPeripheralManagerOptionRestoreIdentifierKey: kBLEBroadcasterRestoreIdentifier,
                                                                             CBPeripheralManagerOptionShowPowerAlertKey: @YES}];
    }
    return self;
}

- (BOOL) startBroadcasting {
    if (self.peripheralManager.state == CBPeripheralManagerStatePoweredOn) {
        if (!self.meshChatService) {
            CBUUID *meshChatServiceUUID = [BLEBroadcaster meshChatServiceUUID];
            self.meshChatService = [[CBMutableService alloc] initWithType:meshChatServiceUUID primary:YES];
            CBUUID *meshChatReadCharacteristicUUID = [BLEBroadcaster meshChatReadCharacteristicUUID];
            CBUUID *meshChatIdentityCharacteristicUUID = [BLEBroadcaster meshChatIdentityCharacteristicUUID];
            
            self.readCharacteristic = [[CBMutableCharacteristic alloc] initWithType:meshChatReadCharacteristicUUID properties:CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable];
            
            self.identityCharacteristic = [[CBMutableCharacteristic alloc] initWithType:meshChatIdentityCharacteristicUUID properties:CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable];
            
            self.meshChatService.characteristics = @[self.readCharacteristic, self.identityCharacteristic];
            [self.peripheralManager addService:self.meshChatService];
        } else {
            DDLogWarn(@"Peripheral Manager already running services");
        }
        if (!self.peripheralManager.isAdvertising) {
            [self.peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey: @[self.meshChatService.UUID],
                                                   CBAdvertisementDataLocalNameKey: @"MeshChat"}];
            return YES;
        } else {
            DDLogWarn(@"Peripheral Manager already advertising");
        }
        
    } else {
        DDLogWarn(@"Peripheral Manager not powered on! %d", (int)self.peripheralManager.state);
    }
    return NO;
}

- (void) stopBroadcasting {
    [self.peripheralManager stopAdvertising];
}

#pragma mark Static Methods


+ (CBUUID*) meshChatServiceUUID {
    return [CBUUID UUIDWithString:kBLEMeshChatServiceUUIDString];
}

+ (CBUUID*) meshChatReadCharacteristicUUID {
    return [CBUUID UUIDWithString:kBLEMeshChatReadCharacteristicUUIDString];
}

+ (CBUUID*) meshChatIdentityCharacteristicUUID {
    return [CBUUID UUIDWithString:kBLEMeshChatIdentityCharacteristicUUIDString];
}


#pragma mark - CBPeripheralManagerDelegate methods

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    DDLogVerbose(@"%@: %@ %d", THIS_FILE, THIS_METHOD, (int)peripheral.state);
    if (peripheral.state == CBPeripheralManagerStatePoweredOn) {
        [self startBroadcasting];
    }
}

- (void) peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error {
    if (error) {
        DDLogError(@"Error starting advertisement: %@", error.userInfo);
    } else {
        DDLogVerbose(@"%@: %@ success!", THIS_FILE, THIS_METHOD);
    }
}

- (void) peripheralManager:(CBPeripheralManager *)peripheral willRestoreState:(NSDictionary *)dict {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    NSArray *restoredServices = dict[CBPeripheralManagerRestoredStateServicesKey];
    NSDictionary *restoredAdvertisementDict = dict[CBPeripheralManagerRestoredStateAdvertisementDataKey];
    NSLog(@"Restored services: %@, ads: %@", restoredServices, restoredAdvertisementDict);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error {
    if (error) {
        DDLogError(@"Error starting service: %@", error.description);
    } else {
        DDLogVerbose(@"%@: %@ %@", THIS_FILE, THIS_METHOD, service);
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic {
    DDLogVerbose(@"%@: %@ %@ %@", THIS_FILE, THIS_METHOD, central, characteristic);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic {
    DDLogVerbose(@"%@: %@ %@ %@", THIS_FILE, THIS_METHOD, central, characteristic);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request {
    DDLogVerbose(@"%@: %@ %@", THIS_FILE, THIS_METHOD, request);
    CBUUID *requestUUID = request.characteristic.UUID;
    NSData *responseData = nil;
    if ([requestUUID isEqual:self.readCharacteristic.UUID]) {
        responseData = [@"read" dataUsingEncoding:NSUTF8StringEncoding];
    } else if ([requestUUID isEqual:self.identityCharacteristic.UUID]) {
        responseData = [@"ident" dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    if (responseData) {
        request.value = responseData;
        [peripheral respondToRequest:request withResult:CBATTErrorSuccess];
    } else {
        [peripheral respondToRequest:request withResult:CBATTErrorReadNotPermitted];
    }
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests {
    DDLogVerbose(@"%@: %@ %@", THIS_FILE, THIS_METHOD, requests);
}

- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral {
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

@end
