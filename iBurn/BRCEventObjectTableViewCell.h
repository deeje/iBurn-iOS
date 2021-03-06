//
//  BRCEventObjectTableViewCell.h
//  iBurn
//
//  Created by Christopher Ballinger on 7/29/14.
//  Copyright (c) 2014 Burning Man Earth. All rights reserved.
//

#import "BRCDataObjectTableViewCell.h"

@interface BRCEventObjectTableViewCell : BRCDataObjectTableViewCell

@property (strong, nonatomic) IBOutlet UILabel *eventTypeLabel;
@property (strong, nonatomic) IBOutlet UILabel *locationLabel;

@end
