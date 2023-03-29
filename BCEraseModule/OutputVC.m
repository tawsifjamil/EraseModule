//
//  OutputVC.m
//  BCEraseModule
//
//  Created by BCL Device 3 on 15/3/23.
//

#import "OutputVC.h"

@interface OutputVC ()

@property (weak, nonatomic) IBOutlet UIImageView *outputImageView;

@end

@implementation OutputVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _outputImageView.image = _outputImage;
}


- (IBAction)goBack:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

@end
