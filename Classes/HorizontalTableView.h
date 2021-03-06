//
//  HorizontalTableView.h
//  Scroller
//
//  Created by Martin Volerich on 5/22/10.
//  Copyright 2010 Martin Volerich - Bill Bear Technologies. All rights reserved.
//

// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the "Software"), to deal in the Software without restriction, including without
// limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so, subject to the following
// conditions:
// 
// The above copyright notice and this permission notice shall be included in all copies or substantial
// portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
// LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
// AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
// OR OTHER DEALINGS IN THE SOFTWARE.

#import <UIKit/UIKit.h>

@class HorizontalTableView;

@protocol HorizontalTableViewDelegate <NSObject, UIScrollViewDelegate>

- (void)tableView:(HorizontalTableView *)tableView didSelectColumnAtIndex:(NSInteger)index;
- (void)tableView:(HorizontalTableView *)tableView showingColumnAtIndex:(NSInteger)index;

@end

@protocol HorizontalTableViewDataSource <NSObject>

- (NSInteger)numberOfColumnsForTableView:(HorizontalTableView *)tableView;
- (UIView *)tableView:(HorizontalTableView *)tableView viewForIndex:(NSInteger)index;
- (CGFloat)columnWidthForTableView:(HorizontalTableView *)tableView;

@end

@interface HorizontalTableView : UIScrollView
{
}

@property (weak, nonatomic) IBOutlet id<HorizontalTableViewDelegate> delegate;
@property (weak, nonatomic) IBOutlet id<HorizontalTableViewDataSource> dataSource;

@property (nonatomic, assign) CGFloat animationDuration;
@property (nonatomic, assign) BOOL loopAnimation;
@property (nonatomic, assign) NSInteger animationScrollByCells;
@property (nonatomic, readonly) NSUInteger currentPageIndex;

- (void)refreshData;
- (UIView *)dequeueColumnView;
- (void)startAnimation;
- (void)stopAnimation;
- (void)scrollToPage:(NSInteger)page animated:(BOOL)animated;

@end
