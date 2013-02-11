//
//  AppDelegate.m
//  uPINPoint Live
//
//  Created by Nicholas Ver Voort on 1/10/13.
//  Copyright (c) 2013 Engaging Computing Group. All rights reserved.
//

#import "AppDelegate.h"
#import <IOKit/Hid/IOHIDManager.h>
#import <CoreFoundation/CFSet.h>
#import "uPINPoint.h"

@implementation AppDelegate

id selfRef;
NSColor *colorRed, *colorGreen, *colorWhite;
IOHIDDeviceRef uPPT;
uPINPoint *pinMan;

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    selfRef = self;
    colorRed =  [NSColor colorWithCalibratedRed:0.7f green:0.0f blue:0.0f alpha:1.0f];
    colorGreen = [NSColor colorWithCalibratedRed:0.0f green:0.7f blue:0.0f alpha:1.0f];
    colorWhite = [NSColor colorWithCalibratedRed:1.0f green:1.0f blue:1.0f alpha:1.0f];
    
    pinMan = [[uPINPoint alloc] init];
    
    int vendorID = 0x04D8;
    int productID = 0x0054;
    //Create a HID Manager
    IOHIDManagerRef hidManager = IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);
    
    //Create a dictionary and limit it to the uPPT
    CFMutableDictionaryRef dict = CFDictionaryCreateMutable (kCFAllocatorDefault, 2, &kCFTypeDictionaryKeyCallBacks,
                                                             &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(dict, CFSTR(kIOHIDVendorIDKey), CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &vendorID));
    CFDictionarySetValue(dict, CFSTR(kIOHIDProductIDKey), CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &productID));
    IOHIDManagerSetDeviceMatching(hidManager, dict);
    
    //Register a callback for USB detection
    IOHIDManagerRegisterDeviceMatchingCallback(hidManager, &Handle_DeviceMatchingCallback, NULL);
    //Register a callback for USB detection
    IOHIDManagerRegisterDeviceRemovalCallback(hidManager, &Handle_DeviceRemovalCallback, NULL);
    //Register the HID Manager on our app's run loop
    IOHIDManagerScheduleWithRunLoop(hidManager, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
    
    //Open the HID Manager
    IOReturn IOReturn = IOHIDManagerOpen(hidManager, kIOHIDOptionsTypeNone);
    if(IOReturn) NSLog(@"IOHIDManagerOpen failed."); //Couldn't open the HID Manager!
    
}

- (void)changeConnectionStatusView:(Boolean)status {
    if(status) {
        [self.cStatus setStringValue:@"Connected"];
        [self.cStatus setBackgroundColor:(colorGreen)];
        [self.cStatus setTextColor:(colorWhite)];
    } else {
        [self.cStatus setStringValue:@"Disconnected"];
        [self.cStatus setBackgroundColor:(colorRed)];
        [self.cStatus setTextColor:(colorWhite)];
    }
}

- (IBAction)setTime:(id)sender {
    NSLog(@"Pressed the set time button");
}

- (void)showTime {
    [self.dayField setStringValue:[NSString stringWithFormat:@"%d", [pinMan day]]];
    [self.monthField setStringValue:[NSString stringWithFormat:@"%d", [pinMan month]]];
    [self.yearField setStringValue:[NSString stringWithFormat:@"%d", [pinMan year]]];
    [self.hourField setStringValue:[NSString stringWithFormat:@"%d", [pinMan hour]]];
    [self.minuteField setStringValue:[NSString stringWithFormat:@"%02d", [pinMan minute]]];
    [self.secondField setStringValue:[NSString stringWithFormat:@"%02d", [pinMan second]]];
}

static void Handle_DeviceMatchingCallback(void *inContext, IOReturn inResult, void *inSender, IOHIDDeviceRef inIOHIDDeviceRef){
    if(USBDeviceCount(inSender) == 1) {
        [selfRef changeConnectionStatusView:true];
        uPPT = inIOHIDDeviceRef;
        [pinMan init:uPPT];
    }
}

static void Handle_DeviceRemovalCallback(void *inContext, IOReturn inResult, void *inSender, IOHIDDeviceRef inIOHIDDeviceRef){
    if(USBDeviceCount(inSender) == 0) {
        [selfRef changeConnectionStatusView:false];
        [pinMan deinit];
        uPPT = NULL;
    }
}

static long USBDeviceCount(IOHIDManagerRef HIDManager) {
    CFSetRef devSet = IOHIDManagerCopyDevices (HIDManager);
    if( devSet ) {
        return CFSetGetCount(devSet);
    }
    return 0;
}
@end
