// 
// Copyright (c) 2023 Beijing Volcano Engine Technology Ltd.
// SPDX-License-Identifier: MIT
// 

#import "LiveShareUserModel.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LiveShareUserCollectionViewCell : UICollectionViewCell

@property(nonatomic, strong) LiveShareUserModel *userModel;

@property(nonatomic, assign) NSInteger volume;

@end

NS_ASSUME_NONNULL_END
