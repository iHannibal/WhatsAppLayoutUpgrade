//
//  ViewController.m
//  WhatsAppLayoutUpgrade
//
//  Created by Hannibal Yang on 11/16/14.
//  Copyright (c) 2014 Hannibal Yang. All rights reserved.
//

#import "ViewController.h"
#import "MessageFrame.h"
#import "MessageCell.h"
#import "Message.h"

@interface ViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate> {
    NSMutableArray *_messageFrame;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"messages.plist" ofType:nil];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"file://%@", path]];
    NSArray *array = [NSArray arrayWithContentsOfURL:url];
    
    _messageFrame = [NSMutableArray array];
    Message *previousMSG = nil;
    for (NSDictionary *dict in array) {
        MessageFrame *mf = [[MessageFrame alloc] init];
        Message *msg = [Message messageWithDict:dict];
        BOOL showTime = ![msg.time isEqualToString:previousMSG.time];
        [mf setMessage:msg showTime:showTime];
        [_messageFrame addObject:mf];
        previousMSG = msg;
    }
    
    self.tableView.allowsSelection = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"chat_bg_default.jpg"]];
    
    // 监听系统发出的键盘通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    // 设置发送信息文本框的填充view
    UIView *paddingView = [[UIView alloc] init];
    paddingView.frame = CGRectMake(0, 0, 10, 0);
    paddingView.backgroundColor = [UIColor clearColor];
    _messageField.leftView = paddingView;
    _messageField.leftViewMode = UITextFieldViewModeAlways;
}

#pragma mark - TextField的代理方法
#pragma mark 点击了return key对应的按钮就会调用（键盘右下角的按钮）
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    // 取得文字
    NSString *text = textField.text;
    
    // 添加一条WhatsApp信息(更改模型数据，刷新表格)
    [self addNewMessage:text icon:@"icon01.png" type:MessageTypeMe];
    
    // 自动回复
    [self addNewMessage:[text stringByAppendingString:@"-.- [I will be right back!]"] icon:@"icon02.png" type:MessageTypeOther];
    
    [self.tableView reloadData];
    
    // 清空文本框内容
    textField.text = nil;
    
    // 滚动tableView到最后一行
    NSIndexPath *path = [NSIndexPath indexPathForRow:_messageFrame.count - 1 inSection:0];
    [self.tableView scrollToRowAtIndexPath:path atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    return YES;
}

#pragma mark 添加一条新的消息
- (void)addNewMessage:(NSString *)text icon:(NSString *)icon type:(MessageType)type {
    
    MessageFrame *mf = [[MessageFrame alloc] init];
    Message *m = [[Message alloc] init];
    m.content = text;
    
    // 设置时间
    NSDate *date = [NSDate date];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"HH:mm"; // 格式
    // 将date转成对应格式的字符串
    m.time = [df stringFromDate:date];
    
    m.type = type;
    m.icon = icon;
    MessageFrame *previousMF = [_messageFrame lastObject];
    NSString *previousTime = previousMF.message.time;
    BOOL showTime = ![m.time isEqualToString:previousTime];
    [mf setMessage:m showTime:showTime];
    [_messageFrame addObject:mf];
}

#pragma mark - 键盘处理
#pragma mark 键盘弹出
- (void)keyboardWillShow:(NSNotification *)notification {
    
//    NSLog(@"%@", notification.userInfo);
    // OC的所有集合中只能放对象
//    id rect = notification.userInfo[UIKeyboardFrameEndUserInfoKey];
//    NSLog(@"%@", [rect class]);
    
    // 获取动画时间
    CGFloat duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    // 执行动画
    [UIView animateWithDuration:duration animations:^{
        // 取出键盘的frame
        NSValue *rectValue = notification.userInfo[UIKeyboardFrameEndUserInfoKey];
        CGRect keyboardRect = [rectValue CGRectValue];
        // 让整个控制器的view往上挪动一个键盘的高度
        // transform形变属性还控制平移
        CGFloat translationY = - keyboardRect.size.height;
        self.view.transform = CGAffineTransformMakeTranslation(0, translationY);
    }];

}

#pragma mark 键盘退出
- (void)keyboardWillHide:(NSNotification *)notification {
    
    CGFloat duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView animateWithDuration:duration animations:^{
        // 恒等变换 （回到默认位置，清空所有的transform效果）
        self.view.transform = CGAffineTransformIdentity;
    }];
    
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 代理方法
// 此方法有一个键盘退出的bug，滚动情况下，键盘弹不出
//- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
//    
//    [self.view endEditing:YES];
//}
// 开始拖拽的时候调用一次
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
    // 退出键盘
    [self.view endEditing:YES];
}

#pragma mark - 数据源方法
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _messageFrame.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MessageCell *cell = [tableView dequeueReusableCellWithIdentifier:[MessageCell ID]];
    if (cell == nil) {
        cell = [[MessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[MessageCell ID]];
    }
    cell.messageFrame = _messageFrame[indexPath.row];
    cell.backgroundColor = [UIColor clearColor];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return [_messageFrame[indexPath.row] cellHeight];
}

#pragma mark 监听语音按钮点击
- (IBAction)voiceChat:(UIButton *)sender {
    
    if (_messageField.hidden) { // 显示文本框、隐藏语音按钮
        _messageField.hidden = NO;
        _holdToTalk.hidden = YES;
        // 用户体验优化：弹出键盘
        [_messageField becomeFirstResponder];
        
        // 更换为语音图片
        [sender setBackgroundImage:[UIImage imageNamed:@"chat_bottom_voice_nor.png"] forState:UIControlStateNormal];
        [sender setBackgroundImage:[UIImage imageNamed:@"chat_bottom_voice_press.png"] forState:UIControlStateHighlighted];
        
    } else { // 隐藏文本框，显示语音按钮
        _messageField.hidden = YES;
        _holdToTalk.hidden = NO;
        
        // 用户体验优化：退出键盘
        [_messageField resignFirstResponder];
        // 退出键盘第二种方法
//        [self.view endEditing:YES];
        
        // 更换为键盘图片
        [sender setBackgroundImage:[UIImage imageNamed:@"chat_bottom_keyboard_nor.png"] forState:UIControlStateNormal];
        [sender setBackgroundImage:[UIImage imageNamed:@"chat_bottom_keyboard_press.png"] forState:UIControlStateHighlighted];
    }
}
@end
