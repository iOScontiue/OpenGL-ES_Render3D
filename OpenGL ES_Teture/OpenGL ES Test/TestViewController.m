//
//  TestViewController.m
//  OpenGL ES Test
//
//  Created by 卢育彪 on 2018/11/29.
//  Copyright © 2018年 luyubiao. All rights reserved.
//

/*
 本demo并非使用GLSL语言实现着色，而是采用GLKit框架
 */

#import "TestViewController.h"
#import "TestView.h"

@interface TestViewController ()

//@property (nonatomic, strong) TestView *myView;
@property (nonatomic, strong) EAGLContext *mContext;
//基于OpenGL渲染的一个照明和着色系统：基础效果允许三个灯光和两个纹理被应用到场景中
@property (nonatomic, strong) GLKBaseEffect *mEffect;
@property (nonatomic, assign) int count;

@property (nonatomic, assign) BOOL XB;
@property (nonatomic, assign) BOOL YB;
@property (nonatomic, assign) BOOL ZB;

@property (nonatomic, assign) float xDegree;
@property (nonatomic, assign) float yDegree;
@property (nonatomic, assign) float zDegree;

@end

#define BtnTitleArr @[@"X", @"Y", @"Z"]

@implementation TestViewController
{
    dispatch_source_t timer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    self.myView = (TestView *)self.view;
    
    [self createBtns];
    [self setupContext];
    [self renderLayer];
}

- (void)createBtns
{
    CGFloat wh = 50;
    CGFloat left = 50;
    CGFloat y = self.view.frame.size.height-100-wh;
    for (int i = 0; i < BtnTitleArr.count; i++) {
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(left*(i+1)+wh*i, y, wh, wh)];
        btn.tag = 200+i;
        btn.backgroundColor = [UIColor purpleColor];
        [btn setTitle:BtnTitleArr[i] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.view addSubview:btn];
        [btn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
}

#pragma mark -
#pragma mark - Btn Methods

- (void)btnClick:(UIButton *)sender
{
    switch (sender.tag) {
        case 200:
            _XB = !_XB;
            break;
        case 201:
            _YB = !_YB;
            break;
        case 202:
            _ZB = !_ZB;
            break;
        default:
            break;
    }
}

/*
 Required method for implementing GLKViewControllerDelegate. This update method variant should be used
 when not subclassing GLKViewController. This method will not be called if the GLKViewController object
 has been subclassed and implements -(void)update.
 
 - (void)glkViewControllerUpdate:(GLKViewController *)controller;
 
 如果GLKViewController被子类化了，则须调用-(void)update代理方法，而glkViewControllerUpdate代理方法则不会被调用——否则须调用glkViewControllerUpdate代理方法来更新
 */
- (void)update
{
    GLKMatrix4 modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0.0, 0.0, -2.0);
    modelViewMatrix = GLKMatrix4RotateX(modelViewMatrix, _xDegree);
    modelViewMatrix = GLKMatrix4RotateY(modelViewMatrix, _yDegree);
    modelViewMatrix = GLKMatrix4RotateZ(modelViewMatrix, _zDegree);
    
    self.mEffect.transform.modelviewMatrix = modelViewMatrix;
}

- (void)setupContext
{
    self.mContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.mContext;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [EAGLContext setCurrentContext:self.mContext];
    glEnable(GL_DEPTH_TEST);
}

- (void)renderLayer
{
    //顶点数据：前3个坐标（x、y、z），中间三个颜色（RGB），最后2个坐标（纹理）
    GLfloat attrArr [] = {
        -0.5, 0.5, 0.0,   0.0, 0.0, 0.5,   0.0, 1.0,
        0.5, 0.5, 0.0,    0.0, 0.5, 0.0,   1.0, 1.0,
        -0.5, -0.5, 0.0,  0.5, 0.0, 0.0,   0.0, 0.0,
        0.5, -0.5, 0.0,   0.0, 0.0, 0.5,   1.0, 0.0,
        0.0, 0.0, 1.0,     1.0, 1.0, 1.0,   0.5, 0.5
    };
    
    //绘图索引
    GLuint indices[] =
    {
        0, 3, 2,
        0, 1, 3,
        0, 2, 4,
        0, 4, 1,
        2, 3, 4,
        1, 4, 3,
    };
    
    //顶点个数
    self.count = sizeof(indices)/sizeof(GLuint);
    
    //顶点数据存入缓存区：CPU->GPU
    GLuint buffer;
    glGenBuffers(1, &buffer);
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_STATIC_DRAW);
    
    //索引数据存入缓存区：CPU->GPU
    GLuint index;
    glGenBuffers(1, &index);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    
    //传递顶点数据到着色器指定位置
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*8, NULL);
    
    //顶点颜色数据
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*8, (GLfloat *)NULL + 3);
    
    //顶点纹理数据
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*8, (GLfloat *)NULL + 6);
    
    //加载纹理
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"cTest" ofType:@"jpg"];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@"1", GLKTextureLoaderOriginBottomLeft, nil];
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:options error:nil];
    
    self.mEffect = [[GLKBaseEffect alloc] init];
    self.mEffect.texture2d0.enabled = GL_TRUE;
    self.mEffect.texture2d0.name = textureInfo.name;
    
    //创建透视投影矩阵
    CGSize size = self.view.bounds.size;
    float aspect = fabs(size.width/size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(90.0), aspect, 0.1, 10.0);
    //设置等比缩放
    projectionMatrix = GLKMatrix4Scale(projectionMatrix, 1.0, 1.0, 1.0);
    
    self.mEffect.transform.projectionMatrix = projectionMatrix;
    
    //设置平移：Z轴负方向平移2.0
    GLKMatrix4 modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0.0, 0.0, -2.0);
    self.mEffect.transform.modelviewMatrix = modelViewMatrix;
    
    //设置定时器
    double seconds = 0.1;
    timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, seconds*NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(timer, ^{
        self.xDegree += 0.1*self.XB;
        self.yDegree += 0.1*self.YB;
        self.zDegree += 0.1*self.ZB;
    });
    dispatch_resume(timer);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.3, 0.3, 0.3, 1.0);
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
    
    //准备绘制
    [self.mEffect prepareToDraw];
    //索引绘制
    glDrawElements(GL_TRIANGLES, self.count, GL_UNSIGNED_INT, 0);
}

@end
