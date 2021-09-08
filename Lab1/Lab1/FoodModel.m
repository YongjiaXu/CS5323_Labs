//
//  FoodModel.m
//  Lab1
//
//  Created by xuan zhai on 9/7/21.
//

#import "FoodModel.h"

@implementation FoodModel

@synthesize foodNames = _foodNames;
@synthesize foodDict = _foodDict;


+(FoodModel*)sharedInstance{
    static FoodModel* _sharedInstance = nil;
    
    static dispatch_once_t predicate;
    
    dispatch_once(&predicate, ^{
        _sharedInstance = [[FoodModel alloc] init];
    });
    
    return _sharedInstance;
}

-(NSArray*) foodNames{
    if(!_foodNames){
        _foodNames = @[@"Crispy-Duck", @"Hot-Pot", @"Kong-Bao-Chicken", @"Spicy-Fish", @"Stir-Fry-Pot", @"Sweet-Ribs"];
    }
    return _foodNames;
}


-(NSDictionary*) foodDict{
    if(!_foodDict){
        _foodDict = @{@"Crispy-Duck":[UIImage imageNamed:@"Crispy-Duck"],
                       @"Hot-Pot":[UIImage imageNamed:@"Hot-Pot"],
                       @"Kong-Bao-Chicken":[UIImage imageNamed:@"Kong-Bao-Chicken"],
                      @"Spicy-Fish":[UIImage imageNamed:@"Spicy-Fish"],
                      @"Stir-Fry-Pot":[UIImage imageNamed:@"Stir-Fry-Pot"],
                      @"Sweet-Ribs":[UIImage imageNamed:@"Sweet-Ribs"]
                      
                      
        };
    }
    return _foodDict;
}


-(UIImage*)getImageWithName:(NSString*)name{
    return self.foodDict[name];
}


-(UIImage*)getImageWithIndex:(NSInteger)index{
    NSString* name = self.foodNames[index];
    return self.foodDict[name];
}


-(NSInteger)numberOfFoods{
    return [self.foodNames count];
}


-(NSString*)getFoodNameForIndex:(NSInteger)index{
    return self.foodNames[index];
}




@end
