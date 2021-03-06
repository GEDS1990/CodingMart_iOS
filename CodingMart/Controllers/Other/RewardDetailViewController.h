//
//  RewardDetailViewController.h
//  CodingMart
//
//  Created by Ease on 15/10/29.
//  Copyright © 2015年 net.coding. All rights reserved.
//

#import "MartWebViewController.h"
#import "Reward.h"

@interface RewardDetailViewController : MartWebViewController
+ (instancetype)vcWithReward:(Reward *)reward;
+ (instancetype)vcWithRewardId:(NSUInteger)rewardId;
@end
