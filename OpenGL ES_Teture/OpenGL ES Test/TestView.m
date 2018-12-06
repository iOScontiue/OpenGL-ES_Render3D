//
//  TestView.m
//  OpenGL ES Test
//
//  Created by 卢育彪 on 2018/11/29.
//  Copyright © 2018年 luyubiao. All rights reserved.
//

#import "TestView.h"

@interface TestView()

@property (nonatomic, strong) EAGLContext *mContext;
@property (nonatomic, strong) GLKBaseEffect *mEffect;
@property (nonatomic, assign) int count;

@property (nonatomic, assign) BOOL XB;
@property (nonatomic, assign) BOOL YB;
@property (nonatomic, assign) BOOL ZB;

@property (nonatomic, assign) float xDegree;
@property (nonatomic, assign) float yDegree;
@property (nonatomic, assign) float zDegree;


@end

@implementation TestView
{
    dispatch_source_t timer;
}

- (void)layoutSubviews
{
    [self setupContext];
    [self renderLayer];
}

- (void)setupContext
{
    self.mContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    GLKView *view = (GLKView *)self;
    view.context = self.mContext;
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [EAGLContext setCurrentContext:self.mContext];
    glEnable(GL_DEPTH_TEST);
}

- (void)renderLayer
{
    GLfloat attrArr [] = {
        -0.5, 0.5, 0.0,   0.0, 0.0, 0.5,   0.0, 1.0,
        0.5, 0.5, 0.0,    0.0, 0.5, 0.0,   1.0, 1.0,
        -0.5, -0.5, 0.0,  0.5, 0.0, 0.0,   0.0, 0.0,
        0.5, -0.5, 0.0,   0.0, 0.0, 0.5,   1.0, 0.0,
        0.0, 0.0, 1.0,     1.0, 1.0, 1.0,   0.5, 0.5
    };
    
    GLuint indices[] =
    {
        0, 3, 2,
        0, 1, 3,
        0, 2, 4,
        0, 4, 1,
        2, 3, 4,
        1, 4, 3,
    };
    
    self.count = sizeof(indices)/sizeof(GLuint);
    
    GLuint buffer;
    glGenBuffers(1, &buffer);
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_STATIC_DRAW);
    
    GLuint index;
    glGenBuffers(1, &index);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, index);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*8, NULL);
    
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*8, (GLfloat *)NULL + 3);
    
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*8, (GLfloat *)NULL + 6);
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"cTest" ofType:@"jpg"];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@"1", GLKTextureLoaderOriginBottomLeft, nil];
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:options error:nil];
    
    self.mEffect = [[GLKBaseEffect alloc] init];
    self.mEffect.texture2d0.enabled = GL_TRUE;
    self.mEffect.texture2d0.name = textureInfo.name;
    
    CGSize size = self.bounds.size;
    float aspect = fabs(size.width/size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(90.0), aspect, 0.1, 10.0);
    projectionMatrix = GLKMatrix4Scale(projectionMatrix, 1.0, 1.0, 1.0);
    
    self.mEffect.transform.projectionMatrix = projectionMatrix;
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4Translate(GLKMatrix4Identity, 0.0, 0.0, -2.0);
    self.mEffect.transform.modelviewMatrix = modelViewMatrix;
    
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

@end
