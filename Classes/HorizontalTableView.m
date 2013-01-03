//
//  HorizontalTableView.m
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

#import "HorizontalTableView.h"

#define kColumnPoolSize 5

@interface HorizontalTableView()

@property (nonatomic, assign) NSUInteger currentPhysicalPageIndex;
@property (nonatomic, assign) NSInteger visibleColumnCount;
@property (nonatomic, assign) NSUInteger physicalPageIndex;
@property (nonatomic, assign) CGFloat columnWidth;

@property (nonatomic, strong) NSMutableArray *pageViews;
@property (nonatomic, strong) NSMutableArray *columnPool;
@property (nonatomic, strong) NSTimer *timer;

- (void)prepareView;
- (void)layoutPages;
- (void)currentPageIndexDidChange;
- (NSUInteger)numberOfPages;
- (void)layoutPhysicalPage:(NSUInteger)pageIndex;
- (UIView *)viewForPhysicalPage:(NSUInteger)pageIndex;
- (void)removeColumn:(NSInteger)index;

@end


@implementation HorizontalTableView

- (void)refreshData
{
    self.pageViews = [NSMutableArray array];
	// to save time and memory, we won't load the page views immediately
	NSUInteger numberOfPhysicalPages = [self numberOfPages];
	for (NSUInteger i = 0; i < numberOfPhysicalPages; ++i)
		[self.pageViews addObject:[NSNull null]];
    
    [self setNeedsLayout];
}

- (NSUInteger)numberOfPages
{
	NSInteger numPages = 0;
    if (_dataSource)
        numPages = [_dataSource numberOfColumnsForTableView:self];
    return numPages;
}

- (UIView *)viewForPhysicalPage:(NSUInteger)pageIndex
{
	NSParameterAssert(pageIndex >= 0);
	NSParameterAssert(pageIndex < [self.pageViews count]);
	
	UIView *pageView = nil;
	if ([self.pageViews objectAtIndex:pageIndex] == [NSNull null]) {
        
        if (_dataSource) {
            pageView = [_dataSource tableView:self viewForIndex:pageIndex];
            [self setGestureRecognizerForView:pageView];
            [self.pageViews replaceObjectAtIndex:pageIndex withObject:pageView];
            [self addSubview:pageView];
            DLog(@"View loaded for page %d", pageIndex);
        }
	} else {
		pageView = [self.pageViews objectAtIndex:pageIndex];
	}
	return pageView;
}

- (void)setGestureRecognizerForView:(UIView *)view
{
    if ([[view gestureRecognizers] count] > 0) {
        return;
    }
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc]
                                                    initWithTarget:self
                                                    action:@selector(tappedColumn:)];
    
    [view addGestureRecognizer:tapGestureRecognizer];
}

- (void)tappedColumn:(id)sender
{
    if (self.delegate) {
        UITapGestureRecognizer *tapGestureRecognizer = (UITapGestureRecognizer *)sender;
        [self.delegate tableView:self didSelectColumnAtIndex:[self.pageViews indexOfObject:tapGestureRecognizer.view]];
    }
}

- (CGSize)pageSize
{
    CGRect rect = self.bounds;
	return rect.size;
}

- (CGFloat)columnWidth
{
    if (!_columnWidth) {
        if (_dataSource) {
            CGFloat width = [_dataSource columnWidthForTableView:self];
            _columnWidth = width;
        }
    }
    return _columnWidth;

}

- (BOOL)isPhysicalPageLoaded:(NSUInteger)pageIndex
{
	return [self.pageViews objectAtIndex:pageIndex] != [NSNull null];
}

- (void)layoutPhysicalPage:(NSUInteger)pageIndex
{
	UIView *pageView = [self viewForPhysicalPage:pageIndex];
    CGFloat viewWidth = pageView.bounds.size.width;
	CGSize pageSize = [self pageSize];
    
    CGRect rect = CGRectMake(viewWidth * pageIndex, 0, viewWidth, pageSize.height);
	pageView.frame = rect;
}

- (void)awakeFromNib
{
    [self prepareView];
}

- (void)queueColumnView:(UIView *)vw
{
    if ([self.columnPool count] >= kColumnPoolSize) {
        return;
    }
    [self.columnPool addObject:vw];
}

- (UIView *)dequeueColumnView
{
    UIView *vw = [self.columnPool lastObject];
    if (vw) {
        [self.columnPool removeLastObject];
        DLog(@"Supply from reuse pool");
    }
    return vw;
}

- (void)removeColumn:(NSInteger)index
{
    if ([self.pageViews objectAtIndex:index] != [NSNull null]) {
        DLog(@"Removing view at position %d", index);
        UIView *vw = [self.pageViews objectAtIndex:index];
        [self queueColumnView:vw];
        [vw removeFromSuperview];
        [self.pageViews replaceObjectAtIndex:index withObject:[NSNull null]];
    }
}

- (void)currentPageIndexDidChange
{
    CGSize pageSize = [self pageSize];
    CGFloat columnWidth = [self columnWidth];
    _visibleColumnCount = pageSize.width / columnWidth + 2;
    
    NSInteger leftMostPageIndex = -1;
    NSInteger rightMostPageIndex = 0;
    
    for (NSInteger i = -2; i < _visibleColumnCount; i++) {
        NSInteger index = _currentPhysicalPageIndex + i;
        if (index < [self.pageViews count] && (index >= 0)) {
            [self layoutPhysicalPage:index];
            if (leftMostPageIndex < 0)
                leftMostPageIndex = index;
            rightMostPageIndex = index;
        }
    }
    
    // clear out views to the left
    for (NSInteger i = 0; i < leftMostPageIndex; i++) {
        [self removeColumn:i];
    }
    
    // clear out views to the right
    for (NSInteger i = rightMostPageIndex + 1; i < [self.pageViews count]; i++) {
        [self removeColumn:i];
    }
}

- (void)layoutPages
{
    CGSize pageSize = self.bounds.size;
	self.contentSize = CGSizeMake([self.pageViews count] * [self columnWidth], pageSize.height);
}

- (id)init
{
    self = [super init];
    if (self) {
        self.animationScrollByCells = 1;
        [self prepareView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.animationScrollByCells = 1;
    }
    return self;
}

- (void)prepareView
{
    _animationDuration = 5.0;
	_columnPool = [[NSMutableArray alloc] initWithCapacity:kColumnPoolSize];
    _columnWidth = 0.0;
    [self refreshData];
}


- (NSUInteger)physicalPageIndex
{
    NSUInteger page = self.contentOffset.x / [self columnWidth];
    return page;
}

- (void)setPhysicalPageIndex:(NSUInteger)newIndex
{
	self.contentOffset = CGPointMake(newIndex * [self pageSize].width, 0);
}

- (void)setContentOffset:(CGPoint)contentOffset
{
    [super setContentOffset:contentOffset];
    
    NSUInteger newPageIndex = self.physicalPageIndex;
	if (newPageIndex == _currentPhysicalPageIndex) return;
	_currentPhysicalPageIndex = newPageIndex;
	_currentPageIndex = newPageIndex;
	
	[self currentPageIndexDidChange];
    
    CGSize rect = [self contentSize];
    DLog(@"CSize = %@", NSStringFromCGSize(rect));
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


- (void)layoutSubviews
{
    [self layoutPages];
    [self currentPageIndexDidChange];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	// adjust frames according to the new page size - this does not cause any visible changes
	[self layoutPages];
	self.physicalPageIndex = _currentPhysicalPageIndex;
	
	// unhide
	for (NSUInteger pageIndex = 0; pageIndex < [self.pageViews count]; ++pageIndex)
		if ([self isPhysicalPageLoaded:pageIndex])
			[self viewForPhysicalPage:pageIndex].hidden = NO;
	
    self.contentSize = CGSizeMake([self.pageViews count] * [self columnWidth], [self pageSize].height);

    [self currentPageIndexDidChange];
}


- (void)dealloc
{
    _columnPool = nil;
    _pageViews = nil;
}

#pragma mark - Autoscrolling methods

- (void)startAnimation
{
    if (_timer != nil) {
        return;
    }
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:_animationDuration
                                              target:self
                                            selector:@selector(onTimer:)
                                            userInfo:nil
                                             repeats:YES];
}

- (void)stopAnimation
{
    if (_timer == nil) {
        return;
    }
    
    [_timer invalidate];
    _timer = nil;
}

- (void)onTimer:(id)sender
{
    if (_currentPageIndex + _animationScrollByCells < [self numberOfPages]) {
        [self scrollToPage:_currentPageIndex + _animationScrollByCells animated:YES];
    } else if (_loopAnimation) {
        [self scrollToPage:0 animated:YES];
    } else {
        [self stopAnimation];
    }
}

- (void)scrollToPage:(NSInteger)page animated:(BOOL)animated
{
    CGFloat offsetX = [self columnWidth] * page;
    
    if (offsetX >= (self.contentSize.width - self.frame.size.width)) {
        offsetX = (self.contentSize.width - self.frame.size.width);
    }
    
    [self setContentOffset:CGPointMake(offsetX, 0.0)
                  animated:animated];
    
    if (self.delegate) {
        [self.delegate tableView:self showingColumnAtIndex:page];
    }
}

@end
