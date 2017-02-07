//
//  ViewController.m
//  PieChartTest
//
//  Created by Neil Schreiber on 2/1/17.
//  Copyright © 2017 Neil Schreiber. All rights reserved.
//

#import "ViewController.h"

#import "PieChartTest-Swift.h"

@interface BeginEnd: NSObject

@property (assign) NSUInteger         begin;
@property (assign) NSUInteger         end;

@end

@implementation BeginEnd

@end

@interface ViewController () <
    PieChartViewDelegateProtocol,
    PieChartViewDataSourceProtocol
>

@property (weak) IBOutlet PieChartView          *pieChartView;

@property (assign) NSUInteger                   numberOfMajorSlices;
@property (assign) NSUInteger                   numberOfMinorSlices;

@property (strong) NSMutableArray               *beginEndPoints;
@property (strong) NSMutableArray               *colors;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.pieChartView.delegate = self;
    self.pieChartView.dataSource = self;
    self.pieChartView.shouldAnimate = YES;
    
    [self computeNumberOfSlices];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - PieChartViewDataSource

- (NSUInteger) numberOfMajorSlicesInPieChartView:(PieChartView *)pieCharView {
    return self.numberOfMajorSlices;
}

- (NSUInteger) numberOfMinorSlicesInPieChartView:(PieChartView *)pieCharView forMajorSlice:(NSUInteger)majorSlice {
    return self.numberOfMinorSlices;
}

- (CGColorRef) pieChartColorForSlice:(PieChartView *)pieChartView sliceIndex:(PieChartViewSliceIndex * _Nonnull)sliceIndex {
    
    return [[self.colors objectAtIndex:sliceIndex.major] CGColor];
}


- (PieChartViewEndPoints *) pieChartEndPointsForSlice:(PieChartView *)pieChartView sliceIndex:(PieChartViewSliceIndex * _Nonnull)sliceIndex {
    NSLog(@"Get end points for major: %ld minor: %ld", sliceIndex.major, sliceIndex.minor);
    BeginEnd *point = [self.beginEndPoints objectAtIndex:sliceIndex.major];

    
    return [[PieChartViewEndPoints alloc] initWithStart:(point.begin + 0.05)  end:(point.end - 0.05)];
}

#pragma mark - PieChartViewDelegate


- (void)computeNumberOfSlices {
    self.numberOfMajorSlices = arc4random_uniform(20) % (20 - 5 + 1) + 5;
    self.numberOfMinorSlices = 1;//(NSUInteger)arc4random_uniform(5);
    if (self.numberOfMajorSlices == 0) {
        self.numberOfMajorSlices = 1;
    }
    if (self.numberOfMinorSlices == 0) {
        self.numberOfMinorSlices = 1;
    }
    NSLog(@"Number of slices: %ld/%ld", self.numberOfMajorSlices, self.numberOfMinorSlices);
    
    self.beginEndPoints = [NSMutableArray new];
    self.colors = [NSMutableArray new];
    
    CGFloat pieSegmentStart = 0;
    CGFloat pieSegmentEnd = 0;
    NSUInteger percentRemaining = 100;
    
    for (NSUInteger i = 0; i < self.numberOfMajorSlices - 1; i++) {
        NSUInteger sliceSize = (NSUInteger)arc4random_uniform(MIN(25,percentRemaining));
        
        pieSegmentEnd = pieSegmentStart + sliceSize;
        
        NSLog(@"Begin: %f End: %f", pieSegmentStart, pieSegmentEnd);
        
        BeginEnd *point = [BeginEnd new];
        point.begin = pieSegmentStart;
        point.end = pieSegmentEnd;
        
        percentRemaining -= sliceSize;
        pieSegmentStart = pieSegmentEnd;
        [self.beginEndPoints addObject:point];
        
        [self.colors addObject:[self randomColor]];
    }
    
    pieSegmentEnd = 100;
    NSLog(@"Begin: %f End: %f", pieSegmentStart, pieSegmentEnd);
    BeginEnd *point = [BeginEnd new];
    point.begin = pieSegmentStart;
    point.end = pieSegmentEnd;
    [self.beginEndPoints addObject:point];
    [self.colors addObject:[self randomColor]];

}

- (UIColor *)randomColor {
    CGFloat red = (CGFloat)arc4random_uniform(255);
    CGFloat green = (CGFloat)arc4random_uniform(255);
    CGFloat blue = (CGFloat)arc4random_uniform(255);
    return [UIColor colorWithRed:red/255 green:green/255 blue:blue/255 alpha:1];
}

- (IBAction)refreshSlices:(id)sender {
    [self computeNumberOfSlices];
    self.pieChartView.shouldAnimate = YES;
    [self.pieChartView refreshSlices];
}

@end
