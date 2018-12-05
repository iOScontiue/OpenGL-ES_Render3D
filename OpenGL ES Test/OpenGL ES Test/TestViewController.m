//
//  TestViewController.m
//  OpenGL ES Test
//
//  Created by 卢育彪 on 2018/11/29.
//  Copyright © 2018年 luyubiao. All rights reserved.
//

#import "TestViewController.h"
#import "TestView.h"

@interface TestViewController ()

@property (nonatomic, strong) TestView *myView;

@end

@implementation TestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.myView = (TestView *)self.view;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
