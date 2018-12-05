//
//  TestView.m
//  OpenGL ES Test
//
//  Created by 卢育彪 on 2018/11/29.
//  Copyright © 2018年 luyubiao. All rights reserved.
//

#import "TestView.h"
#import "GLESMath.h"
#import "GLESUtils.h"
#import <OpenGLES/ES2/gl.h>

/*
 一、理解：
 顶点数据存储在申请的缓冲区中，其由数据总线传递给着色器（如果是片元着色器，还须将顶点转换成片元），再由着色器最终渲染到涂层上；
 二、思路：
 1.设置涂层；
 2.创建上下文；
 3.清空缓存区；
 4.创建渲染缓存区和帧缓存区；
 5.开始绘制；
 */

@interface TestView()
{
    //旋转度数
    float xDegree;
    float yDegree;
    float zDegree;
    //是否旋转
    BOOL bX;
    BOOL bY;
    BOOL bZ;
    //定时器控制旋转
    NSTimer *myTimer;
}

//显示涂层
@property (nonatomic, strong) CAEAGLLayer *myEagLayer;
//渲染上下文
@property (nonatomic, strong) EAGLContext *myContext;
//渲染缓存区
@property (nonatomic, assign) GLuint myColorRenderBuffer;
//帧缓存区
@property (nonatomic, assign) GLuint myColorFrameBuffer;
//数据总线
@property (nonatomic, assign) GLuint myProgram;
//顶点数据
@property (nonatomic, assign) GLuint myVertices;

@end

#define ButtonTitleArr @[@"X", @"Y" ,@"Z"]

@implementation TestView

- (void)layoutSubviews
{
    [self createSubViews];
    [self setupLayer];
    [self setupContext];
    [self deleteBuffers];
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    [self renderLayer];
}

- (void)createSubViews
{
    CGFloat left = 50;
    CGFloat wh = 50;
    CGFloat y = self.frame.size.height-wh-100;
    for (int i = 0; i < ButtonTitleArr.count; i++) {
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(left*(i+1)+wh*i, y, wh, wh)];
        btn.backgroundColor = [UIColor purpleColor];
        [btn setTitle:ButtonTitleArr[i] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        btn.tag = 200+i;
        [self addSubview:btn];
        [btn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
}

#pragma mark -
#pragma mark - Btn Click

- (void)btnClick:(UIButton *)seder
{
    if (!myTimer) {
        myTimer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(reDegree) userInfo:nil repeats:YES];
    }
    
    switch (seder.tag) {
        case 200:
            bX = !bX;
            break;
        case 201:
            bY = !bY;
            break;
        case 202:
            bZ = !bZ;
            break;
        default:
            break;
    }
}

- (void)reDegree
{
    xDegree += bX*5;
    yDegree += bY*5;
    zDegree += bZ*5;
    
    [self renderLayer];
}

- (void)setupLayer
{
    self.myEagLayer = (CAEAGLLayer *)self.layer;
    //全屏缩放
    [self setContentScaleFactor:[[UIScreen mainScreen] scale]];
    self.myEagLayer.opaque = YES;
    
    /*绘制属性
     1.kEAGLDrawablePropertyRetainedBacking:表示绘图表面显示后，是否保留其内容，一般设置为false；
     2.kEAGLDrawablePropertyColorFormat:绘制对象内部的颜色缓存区格式；
     */
    self.myEagLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
}

- (void)setupContext
{
    //指定API版本：ES2
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    //判断是否为空
    if (context == nil) {
        NSLog(@"Create Context Fail!");
        return;
    }
    
    //设置是否成功
    if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"Set Context Fail!");
        return;
    }
    
    self.myContext = context;
}

- (void)deleteBuffers
{
    //删除并置空
    glDeleteBuffers(1, &_myColorRenderBuffer);
    self.myColorRenderBuffer = 0;
    glDeleteBuffers(1, &_myColorFrameBuffer);
    self.myColorFrameBuffer = 0;
}

- (void)setupRenderBuffer
{
    //定义缓存区
    GLuint buffer;
    //申请一个缓存区标志
    glGenRenderbuffers(1, &buffer);
    self.myColorRenderBuffer = buffer;
    //将标志符绑定GL_RENDERBUFFER
    glBindRenderbuffer(GL_RENDERBUFFER, self.myColorRenderBuffer);
    //为myColorRenderBuffer分配内存空间——myColorFrameBuffer为管理者，无须分配
    [self.myContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.myEagLayer];
}

- (void)setupFrameBuffer
{
    GLuint buffer;
    glGenFramebuffers(1, &buffer);
    self.myColorFrameBuffer = buffer;
    glBindFramebuffer(GL_FRAMEBUFFER, self.myColorFrameBuffer);
    //将myColorFrameBuffer装配到GL_COLOR_ATTACHMENT0附着点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, self.myColorRenderBuffer);
    
    //接下来调用OpenGL ES进行绘制处理
}

- (void)renderLayer
{
    //设置窗口背景颜色
    glClearColor(0.0, 0.0, 0.0, 1.0);
    //清空颜色缓存
    glClear(GL_COLOR_BUFFER_BIT);
    //设置视口大小
    CGFloat scale = [[UIScreen mainScreen] scale];
    glViewport(self.frame.origin.x*scale, self.frame.origin.y*scale, self.frame.size.width*scale, self.frame.size.height*scale);
    
    //读取顶点和片元着色器程序
    NSString *vertFile = [[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"glsl"];
    NSString *fragFile = [[NSBundle mainBundle] pathForResource:@"shaderf" ofType:@"glsl"];
    NSLog(@"vertFile:%@", vertFile);
    NSLog(@"fragFile:%@", fragFile);
    
    //判断myProgram是否存在，存在则清空
    if (self.myProgram) {
        glDeleteProgram(self.myProgram);
        self.myProgram = 0;
    }
    
    //加载着色器到myProgram中
    self.myProgram = [self loadShader:vertFile frag:fragFile];
    
    //创建链接
    glLinkProgram(self.myProgram);
    GLint linkSuccess;
    
    //获取链接状态
    glGetProgramiv(self.myProgram, GL_LINK_STATUS, &linkSuccess);
    
    //判断链接是否成功
    if (linkSuccess == GL_FALSE) {
        //获取失败信息
        GLchar message[256];
        glGetProgramInfoLog(self.myProgram, sizeof(message), 0, &message[0]);
        //c字符串转换成oc字符串
        NSString *messageString = [NSString stringWithUTF8String:message];
        NSLog(@"error:%@", messageString);
        return;
    } else {
        //使用myProgram
        glUseProgram(self.myProgram);
    }
    
    //创建绘制索引数组
    GLuint indices[] = {
        0, 3, 2,
        0, 1, 3,
        0, 2, 4,
        0, 4, 1,
        2, 3, 4,
        1, 4, 3
    };
    
    //判断顶点缓存区是否为空，为空则申请一个缓存区标志符
    if (self.myVertices == 0) {
        glGenBuffers(1, &_myVertices);
    }
    
    //----------处理顶点坐标---------
    
    /*顶点数据
     1.前3个坐标值（x、y、z），后3个颜色值（RGB）;
     2.有先后顺序，否则绘制形状完全不同
     */
    GLfloat attrArr[] =
    {
        -0.5f, 0.5f, 0.0f,      1.0f, 0.0f, 1.0f, //左上
        0.5f, 0.5f, 0.0f,       1.0f, 0.0f, 1.0f, //右上
        -0.5f, -0.5f, 0.0f,     1.0f, 1.0f, 1.0f, //左下
        0.5f, -0.5f, 0.0f,      1.0f, 1.0f, 1.0f, //右下
        0.0f, 0.0f, 1.0f,       0.0f, 1.0f, 0.0f, //顶点
    };
    
    //将_myVertices绑定到GL_ARRAY_BUFFER标志符上
    glBindBuffer(GL_ARRAY_BUFFER, _myVertices);
    //把顶点坐标数据从CPU复制到GPU上
    glBufferData(GL_ARRAY_BUFFER, sizeof(attrArr), attrArr, GL_DYNAMIC_DRAW);
    
    //将顶点坐标数据通过myProgram传递到顶点着色器程序的position
    
    //获取顶点属性入口
    GLuint position = glGetAttribLocation(self.myProgram, "position");
    /*传递数据
     1.一行6个数据，前3个为坐标，后3个为颜色；
     2.NULL开始位置：默认为0，指向数组首地址；
     */
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*6, NULL);
    //设置合适的格式从缓存区中读取数据
    glEnableVertexAttribArray(position);
    
    //处理顶点颜色数据：传递到顶点着色器的positionColor
    GLuint positionColor = glGetAttribLocation(self.myProgram, "positionColor");
    glVertexAttribPointer(positionColor, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*6, (float *)NULL +3);
    glEnableVertexAttribArray(positionColor);
    
    //在myProgram中找到透视投影矩阵和模型视图矩阵
    GLuint projectionMatrixSlot = glGetUniformLocation(self.myProgram, "projectionMatrix");
    GLuint modelViewMatrixSlot = glGetUniformLocation(self.myProgram, "modelViewMatrix");
    
    //创建透视投影矩阵并初始化
    float width = self.frame.size.width;
    float height = self.frame.size.height;
    KSMatrix4 _projectionMatrix;
    ksMatrixLoadIdentity(&_projectionMatrix);
    float aspect = width/height;
    ksPerspective(&_projectionMatrix, 30.0, aspect, 5.0f, 20.0f);
    
    //设置glsl里面的投影矩阵
    glUniformMatrix4fv(projectionMatrixSlot, 1, GL_FALSE, (GLfloat *)&_projectionMatrix.m[0][0]);
    
    //开启剔除功能
    glEnable(GL_CULL_FACE);
    
    //创建平移矩阵：Z轴平移-10
    KSMatrix4 _modelViewMatrix;
    ksMatrixLoadIdentity(&_modelViewMatrix);
    ksTranslate(&_modelViewMatrix, 0.0, 0.0, -10.0);
    
    //创建旋转矩阵
    KSMatrix4 _rotationMatrix;
    ksMatrixLoadIdentity(&_rotationMatrix);
    ksRotate(&_rotationMatrix, xDegree, 1.0, 0.0, 0.0);
    ksRotate(&_rotationMatrix, yDegree, 0.0, 1.0, 0.0);
    ksRotate(&_rotationMatrix, zDegree, 0.0, 0.0, 1.0);
    
    //将平移矩阵和旋转矩阵相乘，结果放到模型视图矩阵中
    ksMatrixMultiply(&_modelViewMatrix, &_rotationMatrix, &_modelViewMatrix);
    
    //设置glsl里面的模型视图矩阵
    glUniformMatrix4fv(modelViewMatrixSlot, 1, GL_FALSE, (GLfloat *)&_modelViewMatrix.m[0][0]);
    
    //设置绘制参数：片元、个数、索引数组
    glDrawElements(GL_TRIANGLES, sizeof(indices)/sizeof(indices[0]), GL_UNSIGNED_INT, indices);
    
    //由顶点着色器将缓存区中的数据渲染到显示涂层上
    [self.myContext presentRenderbuffer:GL_RENDERBUFFER];
}

- (GLuint)loadShader:(NSString *)vert frag:(NSString *)frag
{
    //临时变量：顶点着色器、片元着色器
    GLuint verShader, fragShader;
    //创建数据总线：program
    GLuint program = glCreateProgram();
    
    /*编译顶点、片元着色程序
     参数：编译完存储的底层地址、编译类型、编译文件
     */
    [self compileShader:&verShader type:GL_VERTEX_SHADER file:vert];
    [self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:frag];
    
    //创建最终的程序：着色器与program建立连接
    glAttachShader(program, verShader);
    glAttachShader(program, fragShader);
    
    //释放不需要的着色器
    glDeleteShader(verShader);
    glDeleteShader(fragShader);
    
    return program;
}

- (void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    NSString *content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    const GLchar *source = (GLchar *)[content UTF8String];
    
    *shader = glCreateShader(type);
    /*将着色器源码附加到着色器对象上
     参数：要编译的着色器对象、传递的源码字符串数量、着色器程序源码、字符串长度（NULL即终止）
     */
    glShaderSource(*shader, 1, &source, NULL);
    
    //将着色器源码编译成目标代码
    glCompileShader(*shader);
}

//复写类方法：变更layer类型
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

@end
