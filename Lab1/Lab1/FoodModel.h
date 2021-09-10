//
//  FoodModel.h
//  Lab1
//
//  Created by xuan zhai on 9/7/21.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FoodModel : NSObject


+(FoodModel*)sharedInstance;


-(UIImage*)getImageWithName:(NSString*)name;
-(UIImage*)getImageWithIndex:(NSInteger)index;
-(NSInteger)numberOfFoods;
-(NSString*)getFoodNameForIndex:(NSInteger)index;





@property (strong, nonatomic) NSArray* foodNames;
@property (strong, nonatomic) NSMutableDictionary* foodDict;
@property (strong, nonatomic) NSArray* foodCal;



@end

NS_ASSUME_NONNULL_END
