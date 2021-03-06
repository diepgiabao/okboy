/*
 * Copyright (c) 2016, Psiphon Inc.
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#import <UIKit/UIKit.h>
#import "PsiphonSettingsViewController.h"

// Specifier keys for cells in settings menu
#define kClearWebsiteData			@"clearWebsiteData"
#define kMinTlsVersion				@"minTlsVersion"

// Disable Javascript settings key in Privacy.plist
#define kDisableJavascript			@"disableJavascript"

// These strings correspond to the option's value in MinTLSSettings.plist
#define kMinTlsVersionTLS_1_2 @"TLS_1_2"
#define kMinTlsVersionTLS_1_1 @"TLS_1_1"
#define kMinTlsVersionTLS_1_0 @"TLS_1_0"

@interface SettingsViewController : PsiphonSettingsViewController
@end
