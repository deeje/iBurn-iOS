//
//  BRCDataObjectTableViewCell.h
//  iBurn
//
//  Created by Christopher Ballinger on 7/29/14.
//  Copyright (c) 2014 Burning Man Earth. All rights reserved.
//

#import <UIKit/UIKit.h>
@import DOFavoriteButton;
#import <CoreLocation/CoreLocation.h>

@class BRCDataObject;

@interface BRCDataObjectTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet DOFavoriteButton *favoriteButton;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (strong, nonatomic) IBOutlet UILabel *rightSubtitleLabel;

/** If favoriteButtonAction is set, you must save your changes */
@property (nonatomic, copy) void (^favoriteButtonAction)(BRCDataObjectTableViewCell *sender);


- (void) setDataObject:(BRCDataObject*)dataObject;


+ (NSString*) cellIdentifier;

- (void) updateDistanceLabelFromLocation:(CLLocation*)fromLocation dataObject:(BRCDataObject*)dataObject;

+ (Class) cellClassForDataObjectClass:(Class)dataObjectClass;

@end
