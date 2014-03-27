//
//  DBViewController.m
//  ClickTheBox
//
//  Created by Leah Culver on 2/9/14.
//  Copyright (c) 2014 Dropbox. All rights reserved.
//

#import "DBViewController.h"

@interface DBViewController ()

@property (nonatomic, strong) DBDatastore *store;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIView *boxView;

@end

@implementation DBViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Add tap gesture for clicking the box
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(boxViewTapped)];
    [self.boxView addGestureRecognizer:tapGestureRecognizer];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Check if user is logged in
    DBAccount *account = [[DBAccountManager sharedManager] linkedAccount];
    if (account != nil) {
        [self userLoggedIn];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    // Stop listening for changes to the datastore
    if (self.store) {
        [self.store removeObserver:self];
    }
    self.store = nil;
}

#pragma mark - Helpers

- (void)userLoggedIn
{
    // Hide login UI
    [self.loginButton setHidden:YES];

    // Initialize DBDatastore
    DBAccount *account = [[DBAccountManager sharedManager] linkedAccount];
    self.store = [DBDatastore openDefaultStoreForAccount:account error:nil];
    DBTable *table = [self.store getTable:@"state"];
    [table setResolutionRule:DBResolutionMax forField:@"level"];

    // Observe changes to datastore (possibly from other devices)
    __weak typeof(self) weakSelf = self;
    [self.store addObserver:self block:^() {
        if (weakSelf.store.status & DBDatastoreIncoming) {
            [weakSelf.store sync:nil];
            [weakSelf updateCurrentLevel];
        }
    }];
    
    [self updateCurrentLevel];
}

- (void)boxViewTapped
{
    // Update current level record with next level
    DBTable *table = [self.store getTable:@"state"];
    DBRecord *record = [table getRecord:@"current_level" error:nil];
    NSNumber *level = (NSNumber *)[record objectForKey:@"level"];
    NSNumber *nextLevel = [[NSNumber alloc] initWithInteger:[level integerValue] + 1];

    [record setObject:nextLevel forKey:@"level"];
    [self.store sync:nil];

    [self updateCurrentLevel];
}

- (void)updateCurrentLevel
{
    // Update display with the current level
    DBTable *table = [self.store getTable:@"state"];
    DBRecord *record = [table getOrInsertRecord:@"current_level" fields:@{@"level": @0} inserted:nil error:nil];
    NSNumber *level = (NSNumber *)[record objectForKey:@"level"];

    if (level != nil) {
        self.titleLabel.text = [NSString stringWithFormat:@"CTB: LEVEL %d", [level intValue] + 1];

        // At each level halve the size of the box (1, 1/2, 1/4, etc.)
        float scaleFactor = 1.0 / pow(2, [level integerValue]);

        // Animate box resizing
        [UIView animateWithDuration:0.1 animations:^{
            self.boxView.transform = CGAffineTransformMakeScale(scaleFactor, scaleFactor);
        }];
    }

    [self.descriptionLabel setHidden:NO];
    [self.boxView setHidden:NO];
}

#pragma mark - IB Actions

- (IBAction)loginButtonPressed:(id)sender
{
    DBAccount *account = [[DBAccountManager sharedManager] linkedAccount];
    if (account) {
        // App is already linked
        [self userLoggedIn];
    } else {
        // Prompt user to login and link this app
        [[DBAccountManager sharedManager] linkFromController:self];
    }
}

- (IBAction)resetButtonPressed:(id)sender
{
    // Reset level to 0
    DBTable *table = [self.store getTable:@"state"];
    DBRecord *record = [table getRecord:@"current_level" error:nil];

    [record setObject:@0 forKey:@"level"];
    [self.store sync:nil];

    [self updateCurrentLevel];
}

@end
