//
//  MLVCTableViewController.m
//  MyLittleViewController
//
//  Created by derrick on 10/4/13.
//  Copyright (c) 2013 Instructure. All rights reserved.
//

#import "MLVCTableViewController.h"
#import "MLVCCollectionController.h"
#import "MLVCTableViewCellAdapter.h"

@interface MLVCTableViewController ()
@property (nonatomic) RACDisposable *groupInserted, *groupDeleted, *objectInserted, *objectDeleted;
@end

@implementation MLVCTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self.viewModel respondsToSelector:@selector(viewControllerViewDidLoad:)]) {
        [self.viewModel viewControllerViewDidLoad:self];
    }
    
    if ([self.viewModel respondsToSelector:@selector(tableViewControllerViewDidLoad:)]) {
        [self.viewModel tableViewControllerViewDidLoad:self];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([self.viewModel respondsToSelector:@selector(viewController:viewWillAppear:)]) {
        [self.viewModel viewController:self viewWillAppear:animated];
    }
    
    if ([self.viewModel respondsToSelector:@selector(refreshViewModelForced:withCompletionBlock:)]) {
        [self.viewModel refreshViewModelForced:NO withCompletionBlock:nil];
    }
}

- (void)refreshFromRefreshControl:(UIRefreshControl *)refreshControl
{
    [self.viewModel refreshViewModelForced:YES withCompletionBlock:^{
        [refreshControl endRefreshing];
    }];
}

- (void)endObservingCollectionChanges
{
    [self.groupInserted dispose];
    self.groupInserted = nil;
    
    [self.groupDeleted dispose];
    self.groupDeleted = nil;
    
    [self.objectInserted dispose];
    self.objectInserted = nil;
    
    [self.objectDeleted dispose];
    self.objectDeleted = nil;
}

- (void)beginObservingCollectionChanges
{
    __weak MLVCTableViewController *weakSelf = self;
    
    self.groupInserted = [self.viewModel.collectionController.groupsInsertedIndexSetSignal subscribeNext:^(id x) {
        [weakSelf.tableView insertSections:x withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
    
    self.groupDeleted = [self.viewModel.collectionController.groupsDeletedIndexSetSignal subscribeNext:^(id x) {
        [weakSelf.tableView deleteSections:x withRowAnimation:UITableViewRowAnimationFade];
    }];
    
    self.objectInserted = [self.viewModel.collectionController.objectsInsertedIndexPathsSignal subscribeNext:^(id x) {
        [weakSelf.tableView insertRowsAtIndexPaths:x withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
    
    self.objectDeleted = [self.viewModel.collectionController.objectsDeletedIndexPathsSignal subscribeNext:^(id x) {
        [weakSelf.tableView deleteRowsAtIndexPaths:x withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
    
}

- (void)setViewModel:(id<MLVCTableViewModel>)viewModel
{
    if (_viewModel == viewModel) {
        return;
    }
    
    [self endObservingCollectionChanges];
    
    _viewModel = viewModel;
    if (self.isViewLoaded) {
        if ([_viewModel respondsToSelector:@selector(viewControllerViewDidLoad:)]) {
            [_viewModel viewControllerViewDidLoad:self];
        }
        if ([_viewModel respondsToSelector:@selector(tableViewControllerViewDidLoad:)]) {
            [_viewModel tableViewControllerViewDidLoad:self];
        }
        [self.tableView reloadData];
    }
    
    [self beginObservingCollectionChanges];
    
    if ([_viewModel respondsToSelector:@selector(refreshViewModelForced:withCompletionBlock:)]) {
        self.refreshControl = [[UIRefreshControl alloc] init];
        [self.refreshControl addTarget:self action:@selector(refreshFromRefreshControl:) forControlEvents:UIControlEventValueChanged];
    } else {
        self.refreshControl = nil;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.viewModel.collectionController.groups count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    MLVCCollectionControllerGroup *group = self.viewModel.collectionController[section];
    return group.title;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    MLVCCollectionControllerGroup *group = self.viewModel.collectionController[section];
    return [group.objects count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<MLVCTableViewCellAdapter> cellAdapter = [self.viewModel.collectionController objectAtIndexPath:indexPath];
    return [cellAdapter tableViewController:self cellForRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<MLVCTableViewCellAdapter> cellAdapter = [self.viewModel.collectionController objectAtIndexPath:indexPath];
    if ([cellAdapter respondsToSelector:@selector(tableViewController:didSelectRowAtIndexPath:)]) {
        [cellAdapter tableViewController:self didSelectRowAtIndexPath:indexPath];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<MLVCTableViewCellAdapter> cellAdapter = [self.viewModel.collectionController objectAtIndexPath:indexPath];
    if ([cellAdapter respondsToSelector:@selector(tableViewController:heightForRowAtIndexPath:)]) {
        return [cellAdapter tableViewController:self heightForRowAtIndexPath:indexPath];
    }
    return tableView.rowHeight;
}

@end
