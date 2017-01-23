/*
 * Copyright (c) 2016, Psiphon Inc.
 * All rights reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#import "FeedbackViewController.h"
#import "IASKSettingsReader.h"
#import "IASKTextField.h"
#import "IASKPSTextFieldSpecifierViewCell.h"
#import "IASKTextViewCell.h"
#import "FeedbackThumbsCell.h"
#import "PsiphonBrowser-Swift.h"

#define kCommentsFrameHeight 44*3

#define kCommentsSpecifierKey        @"comments"
#define kEmailSpecifierKey           @"email"
#define kFooterTextSpecifierKey      @"footerText"
#define kIntroTextSpecifierKey       @"introText"
#define kPsiphonBannerImage          @"psiphon-banner.png"
#define kSendDiagnosticsSpecifierKey @"sendDiagnostics"
#define kThumbsSpecifierKey          @"thumbs"

@implementation FeedbackViewController {
    FeedbackThumbsCell *_thumbsCell;
    
    IASKTextViewCell *_comments;
    NSString *_commentsPlaceholder;

    IASKTextViewCell *_introCell;
    IASKTextViewCell *_footerCell;
    NSAttributedString *_introText;
    NSAttributedString *_footerText;
    UIFont *_headerAndFooterFont;
    
    UIColor *_greyPlaceholderColor;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    // Add send and cancel buttons
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Send", "Text of button to send feedback")
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(sendFeedback:)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", "Text of button to discard feedback and return to main settings menu")
                                                                             style:UIBarButtonItemStyleDone
                                                                            target:self.navigationController
                                                                            action:@selector(dismissModalViewControllerAnimated:)];
    
    // Get notified when an IASK field changes
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingDidChange:) name:kIASKAppSettingChanged object:nil];
    
    // UISegmentedControl content initialization
    _thumbsCell = [[FeedbackThumbsCell alloc] init];
    
    // Intro and footer text initialization
    _headerAndFooterFont = [UIFont fontWithName:@"HelveticaNeue" size:14.0f];
    _introText = [self generateIntroString];
    _footerText = [self generateFooterString];
    
    // Add psiphon banner logo
    self.tableView.tableHeaderView = [self psiphonBannerHeader];
    self.tableView.sectionFooterHeight = 0.0;
    
    // Comments textView
    _greyPlaceholderColor = [[UIColor alloc] initWithRed:199.0/255 green:199.0/255 blue:205.0/255 alpha:1];
    _commentsPlaceholder = NSLocalizedString(@"What's on your mind? Please leave us your feedback", @"Comments section placeholder text");
}

- (void)sendFeedback:(id)sender
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSInteger selectedThumbIndex = _thumbsCell.segmentedControl.selectedSegmentIndex;
    NSString *comments = (_comments.textView.textColor == [UIColor blackColor]) ? _comments.textView.text: @""; // textview contains placeholder text, user has inputted nothing
    NSString *emailAddress = [userDefaults stringForKey:kEmailSpecifierKey];
    BOOL uploadDiagnostics = [userDefaults boolForKey:kSendDiagnosticsSpecifierKey];
    
    NSString *psiphonConfig = [Appdelegate getPsiphonConfig];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [FeedbackUpload generateAndSendFeedbackWithThumbIndex:selectedThumbIndex
                                                     comments:comments
                                                        email:emailAddress
                                           sendDiagnosticInfo:uploadDiagnostics
                                                psiphonConfig:psiphonConfig];
    });
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - IASK UITableView delegate methods

- (UITableViewCell*)tableView:(UITableView*)tableView cellForSpecifier:(IASKSpecifier*)specifier {
    if ([specifier.key isEqualToString:kCommentsSpecifierKey]) {
        if (_comments == NULL) {
            _comments = [[IASKTextViewCell alloc] init];
            
            [_comments.textView setDelegate:self];
            [_comments.textView setFont:_comments.textView.font];
            [_comments.textView setScrollEnabled:YES];
            [_comments.textView setText:_commentsPlaceholder];
            [_comments.textView setTextColor:_greyPlaceholderColor];
        }
        [_comments setClipsToBounds:YES];
        return _comments;
    } else if ([specifier.key isEqualToString:kThumbsSpecifierKey]) {
        if (_thumbsCell == NULL) {
            _thumbsCell = [[FeedbackThumbsCell alloc] init];
        }
        return _thumbsCell;
    } else if ([specifier.key isEqualToString:kIntroTextSpecifierKey]) {
        if (_introCell == NULL) {
            _introCell = [self createTextCell:_introText
                                         withFont:_headerAndFooterFont];
        }
        return _introCell;
    } else if ([specifier.key isEqualToString:kFooterTextSpecifierKey]) {
        if (_footerCell == NULL) {
            _footerCell = [self createTextCell:_footerText
                                          withFont:_headerAndFooterFont];
        }
        return _footerCell;
    }
    
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    [cell setUserInteractionEnabled:YES];

    return cell;
}

- (CGFloat)tableView:(UITableView*)tableView heightForSpecifier:(IASKSpecifier*)specifier {
    if ([specifier.key isEqualToString:kIntroTextSpecifierKey]) {
        UIEdgeInsets insets = UIEdgeInsetsZero;
        
        // Get insets of cell to textView
        if (_introCell != NULL) {
            insets = _introCell.layoutMargins;
        }
        
        return [self textViewHeightForAttributedText:_introText withInsets:insets];
    } else if ([specifier.key isEqualToString:kCommentsSpecifierKey]) {
        return kCommentsFrameHeight;
    } else if ([specifier.key isEqualToString:kFooterTextSpecifierKey]) {
        UIEdgeInsets insets = UIEdgeInsetsZero;
        
        // Get insets of cell to textView
        if (_footerCell != NULL) {
            insets = _footerCell.layoutMargins;
        }
        
        return [self textViewHeightForAttributedText:_footerText withInsets:insets];
    } else if ([specifier.key isEqualToString:kThumbsSpecifierKey]) {
        return _thumbsCell.requiredHeight;
    }
    
    // Create cell and retrieve default cell height
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    return cell.frame.size.height;
}

#pragma mark - Cell generation helpers

- (CGFloat)textViewHeightForAttributedText: (NSAttributedString*)text withInsets: (UIEdgeInsets)insets {
    if (!UIEdgeInsetsEqualToEdgeInsets(insets, UIEdgeInsetsZero)) {
        insets.top -= 5;
        insets.bottom -= 5;
        insets.left -= 5;
        insets.right -= 5;
    }
    
    IASKTextViewCell *cell = [[IASKTextViewCell alloc] init];
    
    [cell.textView setAttributedText:text];
    [cell.textView setFont:_headerAndFooterFont];
    CGSize size = [cell.textView sizeThatFits:CGSizeMake(self.view.frame.size.width-insets.left-insets.right, FLT_MAX)];
    return size.height+insets.top+insets.bottom;
}

- (IASKTextViewCell*)createTextCell: (NSAttributedString*)text withFont:(UIFont*)font {
    IASKTextViewCell *cell = [[IASKTextViewCell alloc] init];
    
    [cell setBackgroundColor:self.tableView.backgroundColor];
    
    [cell.textView setAttributedText:text];
    [cell.textView setBackgroundColor:self.tableView.backgroundColor];
    [cell.textView setDataDetectorTypes:UIDataDetectorTypeLink];
    [cell.textView setEditable:NO];
    [cell.textView setFont:font];
    [cell.textView setSelectable:YES];
    [cell.textView setTextAlignment:NSTextAlignmentLeft];
    
    [cell.textView setDelegate:self];
    return cell;
}

- (UIImageView*)psiphonBannerHeader {
    CGFloat topPlusBottomOffset = 30;
    
    UIImageView *headerView = [[UIImageView alloc] init];
    headerView.backgroundColor = [UIColor whiteColor];
    headerView.contentMode = UIViewContentModeCenter;
    headerView.image = [UIImage imageNamed:kPsiphonBannerImage];
    headerView.frame = CGRectMake(0, 0, self.view.frame.size.width, headerView.image.size.height + topPlusBottomOffset);
    
    return headerView;
}

-(NSAttributedString*)generateIntroString {
    NSString *faqPhrase = NSLocalizedString(@"Frequently Asked Questions", @"FAQ link text");
    NSString *introTextPart1 = [NSLocalizedString(@"Please let us know how Psiphon is working for you so we can make the system better!", "Introduction text at top of feedback form") stringByAppendingString:@"\n\n"];
    NSString *introTextPart2 = NSLocalizedString(@"You can also find solutions to many common problems in our %@.", "Text referring user to frequently asked questions. %@ is where the separate translation for the phrase 'Frequently Asked Questions' will be placed.");

    NSString *faqText = [NSString stringWithFormat:introTextPart2, faqPhrase];
    NSString *localizedIntroText = [introTextPart1 stringByAppendingString:faqText];
    NSRange range = [localizedIntroText rangeOfString:faqPhrase];
    
    NSMutableAttributedString *intro = [[NSMutableAttributedString alloc] initWithString:localizedIntroText];
    if (range.location != NSNotFound) {
        [intro addAttribute:NSLinkAttributeName
                      value:[[NSURL alloc] initWithString:NSLocalizedString(@"https://psiphon.ca/en/faq.html", @"External link to FAQ")]
                      range: range];
    }
    [intro addAttribute:NSFontAttributeName
                  value:_headerAndFooterFont
                  range:NSMakeRange(0, [localizedIntroText length])];
    
    return intro;
}


- (NSAttributedString*)generateFooterString {
    NSString *privacyPolicyPhrase = NSLocalizedString(@"Privacy Policy", "Privacy Policy link text");
    NSString *feedbackEmail = @"feedback.ios@psiphon.ca";
    
    NSString *localizedTextPart1 = [NSLocalizedString(@"Please note that this diagnostic data does not identify you, and it helps us keep Psiphon running smoothly.", @"Feedback footer text.") stringByAppendingString:@"\n\n"];
    NSString *footerTextPart2 = [NSLocalizedString(@"Learn more about the data we collect in our %@", @"Feedback footer text referring users to privacy policy. %@ is where the separate translation for the phrase 'Privacy Policy' will be placed.") stringByAppendingString:@"\n\n"];
    NSString *footerTextPart3 = NSLocalizedString(@"If the above form is not working or you would like to send screenshots, please email us at %@", @"Feedback footer text referring users to feedback email. %@ is where the separate translation for the email will be placed.");
    
    NSString *localizedTextPart2 = [NSString stringWithFormat:footerTextPart2, privacyPolicyPhrase];
    NSString *localizedTextPart3 = [NSString stringWithFormat:footerTextPart3, feedbackEmail];
    NSString *localizedFooterText = [[localizedTextPart1 stringByAppendingString:localizedTextPart2] stringByAppendingString:localizedTextPart3];
    
    NSRange privacyPolicyTextRange = [localizedFooterText rangeOfString:privacyPolicyPhrase];
    NSRange feedbackEmailTextRange = [localizedFooterText rangeOfString:feedbackEmail];
    NSMutableAttributedString *footer = [[NSMutableAttributedString alloc] initWithString:localizedFooterText];
    
    if (feedbackEmailTextRange.location != NSNotFound) {
        [footer addAttribute:NSLinkAttributeName
                       value:[[NSURL alloc] initWithString:[@"mailto:" stringByAppendingString:feedbackEmail]]
                       range:feedbackEmailTextRange];
    }
    if (privacyPolicyTextRange.location != NSNotFound) {
        [footer addAttribute:NSLinkAttributeName
                       value:[[NSURL alloc] initWithString:NSLocalizedString(@"https://psiphon.ca/en/privacy.html", @"External link to privacy policy")]
                       range:privacyPolicyTextRange];
    }
    [footer addAttribute:NSFontAttributeName
                   value:_headerAndFooterFont
                   range:NSMakeRange(0, [localizedFooterText length])];
    
    return footer;
}

#pragma mark - UITextView delegate methods

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    if ([[URL scheme] containsString:@"mailto"]) { // User has clicked feedback email address
        return YES;
    }
    UIViewController *wvc = [[UIViewController alloc] init];
    UIWebView *wv = [[UIWebView alloc] initWithFrame:self.navigationController.view.bounds];
    wv.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    [wv loadRequest:[NSURLRequest requestWithURL:URL]];
    [wvc.view addSubview:wv];
    
    [self.navigationController pushViewController:wvc animated:YES];
    return NO;
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    if (_comments != NULL && textView == _comments.textView) { // Clear placeholder text when editing begins
        if (textView.textColor != [UIColor blackColor]) {
            [textView setText:@""];
            [textView setTextColor:[UIColor blackColor]];
        }
    }
    
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    if (_comments != NULL && textView == _comments.textView) { // Re-add placeholder text and remove focus if user removes all inputted text
        if (textView.text.length == 0){
            [textView setText:_commentsPlaceholder];
            [textView setTextColor:_greyPlaceholderColor];
            [textView resignFirstResponder];
        }
    }
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
    if (_comments != NULL && textView == _comments.textView) { // Re-add placeholder if focus changes and field is empty
        if (textView.text.length == 0){
            [textView setText:_commentsPlaceholder];
            [textView setTextColor:_greyPlaceholderColor];
            [textView resignFirstResponder];
        }
    }
    return YES;
}

#pragma mark - Getters

- (NSString*)getInputtedEmail
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:kEmailSpecifierKey];
}

- (BOOL)shouldUploadDiagnosticData
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kSendDiagnosticsSpecifierKey];
}

#pragma mark - IASK delegate methods

- (void)settingDidChange:(NSNotification*)notification {
    
}

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end