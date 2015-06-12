//
//  ViewController.m
//  RAGallery
//
//  Created by Richard Adem on 12/06/2015.
//  Copyright (c) 2015 Richard Adem. All rights reserved.
//

#import "ViewController.h"
#import "RAGalleryViewController.h"
#import "AppDelegate.h"

@interface ViewController () <RAGalleryViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *mainImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *openGalleryButton;
@property (nonatomic) NSUInteger currentImageIndex;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.currentImageIndex = 0;
}

- (IBAction)touchUpIn_openGalleryButton:(id)button {
    
    AppDelegate *appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    
    RAGalleryViewController *galleryViewController = [[RAGalleryViewController alloc] initWithStartingPage:self.currentImageIndex
                                                                                             withImageView:self.mainImageView
                                                                                      andApplicationWindow:appDelegate.window];
    galleryViewController.delegate = self;
    
    [self presentViewController:galleryViewController animated:YES completion:nil];
}

#pragma mark - Images

- (UIImage*) imageAtIndex:(NSUInteger) index {
    NSString *filename = [NSString stringWithFormat:@"kitten%tu.jpg", index];
    UIImage *image = [UIImage imageNamed:filename];
    return image;
}

#pragma mark - Gallery view controller delegate

- (NSUInteger) numberOfImagesForGallery:(RAGalleryViewController*) viewController {
    return 4;
}
- (void) gallery:(RAGalleryViewController*) viewController setupImageAtIndex:(NSUInteger) index forImageView:(UIImageView*) imageView {
    imageView.image = [self imageAtIndex:index];
}
- (void) gallery:(RAGalleryViewController*) viewController willCloseFromIndex:(NSUInteger) index {
    self.currentImageIndex = index;
    
    UIImage *mainImage = [self imageAtIndex:index];;
    self.mainImageView.image = mainImage;
    
    CGFloat width, height;
    if (mainImage.size.width > mainImage.size.height) {
        height = CGRectGetHeight([self.mainImageView superview].frame);
        width = (height / mainImage.size.height) * mainImage.size.width;
    } else {
        width = CGRectGetWidth([self.mainImageView superview].frame);
        height = (width / mainImage.size.width) * mainImage.size.height;
    }
    
    
    
    self.mainImageView.frame = CGRectMake(CGRectGetWidth([self.mainImageView superview].frame)/2 - width/2
                                          , CGRectGetHeight([self.mainImageView superview].frame)/2 - height/2
                                          , width
                                          , height);
}


#pragma mark - Memory manager

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
