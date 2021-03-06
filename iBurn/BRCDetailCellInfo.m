//
//  BRCDetailCellInfo.m
//  iBurn
//
//  Created by David Chiles on 7/29/14.
//  Copyright (c) 2014 Burning Man Earth. All rights reserved.
//

#import "BRCDetailCellInfo.h"

#import "BRCRelationshipDetailInfoCell.h"
#import "BRCCampObject.h"
#import "BRCArtObject.h"
#import "BRCEventObject.h"
#import "BRCDatabaseManager.h"
#import "NSDateFormatter+iBurn.h"
#import "BRCEmbargo.h"
#import "BRCAppDelegate.h"
#import "BRCDataObject+Relationships.h"
#import "BRCEventRelationshipDetailInfoCell.h"

@interface BRCDetailCellInfo ()

@property (nonatomic, strong) NSString *key;

@end

@implementation BRCDetailCellInfo


+ (instancetype)detailCellInfoWithKey:(NSString *)key displayName:(NSString *)displayName cellType:(BRCDetailCellInfoType)cellType
{
    BRCDetailCellInfo *cellInfo = [[self alloc] init];
    cellInfo.key = key;
    cellInfo.displayName = displayName;
    cellInfo.cellType = cellType;
    
    return cellInfo;
}

+ (NSArray *)defaultInfoArray
{
    NSMutableArray *defaultArray = [NSMutableArray new];
    
    [defaultArray addObject:[self detailCellInfoWithKey:NSStringFromSelector(@selector(localThumbnailURL)) displayName:@"Image" cellType:BRCDetailCellInfoTypeImage]];
    
    [defaultArray addObject:[self detailCellInfoWithKey:NSStringFromSelector(@selector(title)) displayName:@"Title" cellType:BRCDetailCellInfoTypeText]];
    
    [defaultArray addObject:[self detailCellInfoWithKey:NSStringFromSelector(@selector(playaLocation)) displayName:@"Location" cellType:BRCDetailCellInfoTypeText]];
    
    [defaultArray addObject:[self detailCellInfoWithKey:NSStringFromSelector(@selector(distanceFromLocation:)) displayName:@"Distance" cellType:BRCDetailCellInfoTypeDistanceFromCurrentLocation]];
    
    [defaultArray addObject:[self detailCellInfoWithKey:NSStringFromSelector(@selector(artistName)) displayName:@"Artist Name" cellType:BRCDetailCellInfoTypeText]];
    
    [defaultArray addObject:[self detailCellInfoWithKey:NSStringFromSelector(@selector(artistLocation)) displayName:@"Artist Location" cellType:BRCDetailCellInfoTypeText]];
    
    [defaultArray addObject:[self detailCellInfoWithKey:NSStringFromSelector(@selector(email)) displayName:@"Email" cellType:BRCDetailCellInfoTypeEmail]];
    
    [defaultArray addObject:[self detailCellInfoWithKey:NSStringFromSelector(@selector(url)) displayName:@"Homepage" cellType:BRCDetailCellInfoTypeURL]];
    
    
    [defaultArray addObject:[self detailCellInfoWithKey:NSStringFromSelector(@selector(hometown)) displayName:@"Hometown" cellType:BRCDetailCellInfoTypeText]];
    
    [defaultArray addObject:[self detailCellInfoWithKey:NSStringFromSelector(@selector(detailDescription)) displayName:@"Description" cellType:BRCDetailCellInfoTypeText]];
    
    if ([BRCEmbargo allowEmbargoedData]) {
        [defaultArray addObject:[self detailCellInfoWithKey:NSStringFromSelector(@selector(location)) displayName:@"GPS Coordinates" cellType:BRCDetailCellInfoTypeCoordinates]];
    }
    
    // last update from API
#if DEBUG
    [defaultArray addObject:[self detailCellInfoWithKey:NSStringFromSelector(@selector(lastUpdated)) displayName:@"Last Updated" cellType:BRCDetailCellInfoTypeDate]];
#endif
    
    return defaultArray;
}

+ (instancetype)detailCellInfoWitDisplayName:(NSString *)displayName value:(NSString *)value
{
    BRCDetailCellInfo *cellInfo = [[self alloc] init];
    cellInfo.displayName = displayName;
    cellInfo.value = value;
    return cellInfo;
}

+ (NSArray *)infoArrayForObject:(BRCDataObject *)object
{
    NSArray *defaultArray = [self defaultInfoArray];
    NSMutableArray *finalCellInfoArray = [NSMutableArray new];
    [defaultArray enumerateObjectsUsingBlock:^(BRCDetailCellInfo *cellInfo, NSUInteger idx, BOOL *stop) {
        if ([object respondsToSelector:NSSelectorFromString(cellInfo.key)]) {
            id cellValue = nil;
            // Distance is a 'special' case
            if ([cellInfo.key isEqualToString:NSStringFromSelector(@selector(distanceFromLocation:))]) {
                CLLocation *userLocation = [BRCAppDelegate sharedAppDelegate].locationManager.location;
                CLLocationDistance distance = [object distanceFromLocation:userLocation];
                cellValue = @(distance);
            } else {
                cellValue = [object valueForKey:cellInfo.key];
            }
            if (cellValue != nil && ![cellValue isEqual:[NSNull null]]) {
                //if value is a string check that it has an length
                if ([cellValue isKindOfClass:[NSString class]]) {
                    NSString *valueString = cellValue;
                    if (![valueString length]) {
                        return;
                    }
                } else if ([cellValue isKindOfClass:[NSURL class]]) {
                    NSURL *valueURL = cellValue;
                    if (![[valueURL absoluteString] length]) {
                        return;
                    }
                } else if ([cellValue isKindOfClass:[NSNumber class]]) {
                    if ([cellInfo.key isEqualToString:NSStringFromSelector(@selector(distanceFromLocation:))]) {
                        NSNumber *numberValue = cellValue;
                        double doubleValue = numberValue.doubleValue;
                        if (doubleValue == CLLocationDistanceMax || doubleValue == 0) {
                            return;
                        }
                    }
                }
                cellInfo.value = cellValue;
                
                if (![BRCEmbargo canShowLocationForObject:object]) {
                    if ([cellInfo.key isEqualToString:NSStringFromSelector(@selector(playaLocation))]) {
                        cellInfo.value = @"Restricted";
                    }
                }
                
                //add value and dispaly name to array
                [finalCellInfoArray addObject:cellInfo];
            }
        }
        
    }];
    
    // Add link to full event schedule for Camp and Art objects
    if ([object isKindOfClass:[BRCCampObject class]] ||
        [object isKindOfClass:[BRCArtObject class]]) {
        __block NSArray *events = @[];
        [[BRCDatabaseManager sharedInstance].readConnection readWithBlock:^(YapDatabaseReadTransaction * transaction) {
            events = [object eventsWithTransaction:transaction];
        }];
        if (events.count > 0) {
            BRCEventRelationshipDetailInfoCell *eventsListCell = [[BRCEventRelationshipDetailInfoCell alloc] init];
            eventsListCell.dataObject = object;
            eventsListCell.displayName = @"Events";
            [finalCellInfoArray insertObject:eventsListCell atIndex:0];
        }
    }
    
    
    
    // Special cases for Schedule and Camp for events
    if ([object isKindOfClass:[BRCEventObject class]]) {
        BRCEventObject *event = (BRCEventObject *)object;
        
        
        //Date string
        NSMutableAttributedString *fullScheduleString = nil;
        NSString *timeString = nil;
        if (event.isAllDay) {
            NSString *dayOfWeekLetter = [[NSDateFormatter brc_dayOfWeekDateFormatter] stringFromDate:event.startDate];
            if (dayOfWeekLetter.length >= 3) {
                NSString *firstLetter = [dayOfWeekLetter substringToIndex:3];
                timeString = [NSString stringWithFormat:@"%@ (All Day)", firstLetter];
            }
        }
        else {
            NSDateFormatter *timeOnlyDateFormatter = [NSDateFormatter brc_timeOnlyDateFormatter];
            NSString *startTimeString = [timeOnlyDateFormatter stringFromDate:event.startDate];
            NSString *endTimeString = [timeOnlyDateFormatter stringFromDate:event.endDate];
            timeString = [NSString stringWithFormat:@"%@ - %@", startTimeString, endTimeString];
        }
        NSDateFormatter *dayOfWeekDateFormatter = [NSDateFormatter brc_dayOfWeekDateFormatter];
        NSDateFormatter *shortDateFormatter = [NSDateFormatter brc_shortDateFormatter];
        NSString *dayOfWeekString = [dayOfWeekDateFormatter stringFromDate:event.startDate];
        NSString *shortDateString = [shortDateFormatter stringFromDate:event.startDate];
        NSString *dateString = [NSString stringWithFormat:@"%@ %@", dayOfWeekString, shortDateString];
        NSString *fullString = [NSString stringWithFormat:@"%@\n%@", dateString, timeString];
        fullScheduleString = [[NSMutableAttributedString alloc] initWithString:fullString];
        UIColor *timeColor = [event colorForEventStatus:[NSDate date]];
        NSRange timeRange = NSMakeRange(dateString.length+1, timeString.length);
        [fullScheduleString setAttributes:@{NSForegroundColorAttributeName: timeColor}
                                    range:timeRange];
        
        //Camp relationship
        BRCRelationshipDetailInfoCell *relationshipDetailInfoCell = nil;
        NSString *relationshipUniqueID = nil;
        NSString *relationshipCollection = nil;
        if ([event.hostedByCampUniqueID length]) {
            relationshipDetailInfoCell = [[BRCRelationshipDetailInfoCell alloc] init];
            relationshipDetailInfoCell.displayName = @"Hosted By Camp";
            relationshipUniqueID = event.hostedByCampUniqueID;
            relationshipCollection = [BRCCampObject collection];
        }
        else if ([event.hostedByArtUniqueID length]) {
            relationshipDetailInfoCell = [[BRCRelationshipDetailInfoCell alloc] init];
            relationshipDetailInfoCell.displayName = @"Hosted At Art";
            relationshipUniqueID = event.hostedByArtUniqueID;
            relationshipCollection = [BRCArtObject collection];
        }
        
        if ([relationshipUniqueID length] && [relationshipCollection length]) {
            [[BRCDatabaseManager sharedInstance].readConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
                relationshipDetailInfoCell.dataObject = [transaction objectForKey:relationshipUniqueID inCollection:relationshipCollection];
            }];
        }
        
        
        NSUInteger index = 0;
        
        if (fullScheduleString) {
            BRCDetailCellInfo *scheduleCellInfo = [[self alloc] init];
            scheduleCellInfo.displayName = @"Schedule";
            scheduleCellInfo.value = fullScheduleString;
            scheduleCellInfo.cellType = BRCDetailCellInfoTypeSchedule;
            [finalCellInfoArray insertObject:scheduleCellInfo atIndex:index];
        }
        
        if (relationshipDetailInfoCell) {
            [finalCellInfoArray insertObject:relationshipDetailInfoCell atIndex:index];
        }
    }
    
    
    return finalCellInfoArray;
}

@end
