#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

// ============ PATHS ============
static NSString* appSupportDir() {
    NSString *appSupport = [NSSearchPathForDirectoriesInDomains(
        NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    NSString *appDir = [appSupport stringByAppendingPathComponent:@"RestaurantApp"];
    [[NSFileManager defaultManager] createDirectoryAtPath:appDir
                                  withIntermediateDirectories:YES attributes:nil error:nil];
    return appDir;
}

static NSString* dataFilePath() {
    return [appSupportDir() stringByAppendingPathComponent:@"data.json"];
}

static NSString* backupDir() {
    NSString *dir = [appSupportDir() stringByAppendingPathComponent:@"backups"];
    [[NSFileManager defaultManager] createDirectoryAtPath:dir
                                  withIntermediateDirectories:YES attributes:nil error:nil];
    return dir;
}

static NSString* loadSavedData() {
    NSString *path = dataFilePath();
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSString *data = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        if (data && data.length > 2) return data;
    }
    return nil;
}

static NSString* loadHTML() {
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"app" ofType:@"html"];
    if (bundlePath) {
        return [NSString stringWithContentsOfFile:bundlePath encoding:NSUTF8StringEncoding error:nil];
    }
    NSString *execPath = [[NSBundle mainBundle] executablePath];
    NSString *execDir = [execPath stringByDeletingLastPathComponent];
    NSString *devPath = [[execDir stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"resources/app.html"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:devPath]) {
        return [NSString stringWithContentsOfFile:devPath encoding:NSUTF8StringEncoding error:nil];
    }
    NSString *sameDirPath = [execDir stringByAppendingPathComponent:@"app.html"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:sameDirPath]) {
        return [NSString stringWithContentsOfFile:sameDirPath encoding:NSUTF8StringEncoding error:nil];
    }
    return @"<html><body><h1>Error: app.html no encontrado</h1></body></html>";
}

// ============ APP DELEGATE ============
@interface AppDelegate : NSObject <NSApplicationDelegate, WKScriptMessageHandler, WKNavigationDelegate>
@property (strong) NSWindow *window;
@property (strong) WKWebView *webView;
@property (strong) WKWebView *printWebView;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSScreen *screen = [NSScreen mainScreen];
    NSRect screenFrame = screen.visibleFrame;
    CGFloat w = screenFrame.size.width * 0.88;
    CGFloat h = screenFrame.size.height * 0.92;
    NSRect frame = NSMakeRect(0, 0, w, h);

    NSWindowStyleMask style = NSWindowStyleMaskTitled |
                               NSWindowStyleMaskClosable |
                               NSWindowStyleMaskMiniaturizable |
                               NSWindowStyleMaskResizable;

    self.window = [[NSWindow alloc] initWithContentRect:frame
                                              styleMask:style
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
    [self.window setTitle:@"RestaurantApp - Sistema de Restaurante"];
    [self.window setMinSize:NSMakeSize(1024, 700)];
    [self.window center];

    self.window.appearance = [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
    self.window.titlebarAppearsTransparent = YES;
    self.window.backgroundColor = [NSColor colorWithRed:0.059 green:0.067 blue:0.090 alpha:1.0];

    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    WKUserContentController *controller = [[WKUserContentController alloc] init];
    [controller addScriptMessageHandler:self name:@"cpp"];
    config.userContentController = controller;
    config.websiteDataStore = [WKWebsiteDataStore defaultDataStore];

    self.webView = [[WKWebView alloc] initWithFrame:self.window.contentView.bounds configuration:config];
    self.webView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.webView.navigationDelegate = self;
    [self.webView setValue:@NO forKey:@"drawsBackground"];

    NSString *html = loadHTML();
    [self.webView loadHTMLString:html baseURL:nil];

    [self.window.contentView addSubview:self.webView];
    [self.window makeKeyAndOrderFront:nil];
    [self setupMenuBar];
}

- (void)setupMenuBar {
    NSMenu *menuBar = [[NSMenu alloc] init];
    NSMenuItem *appMenuItem = [[NSMenuItem alloc] init];
    NSMenu *appMenu = [[NSMenu alloc] initWithTitle:@"RestaurantApp"];
    [appMenu addItemWithTitle:@"Acerca de RestaurantApp" action:@selector(orderFrontStandardAboutPanel:) keyEquivalent:@""];
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItemWithTitle:@"Salir" action:@selector(terminate:) keyEquivalent:@"q"];
    appMenuItem.submenu = appMenu;
    [menuBar addItem:appMenuItem];

    NSMenuItem *editMenuItem = [[NSMenuItem alloc] init];
    NSMenu *editMenu = [[NSMenu alloc] initWithTitle:@"Editar"];
    [editMenu addItemWithTitle:@"Deshacer" action:@selector(undo:) keyEquivalent:@"z"];
    [editMenu addItemWithTitle:@"Rehacer" action:@selector(redo:) keyEquivalent:@"Z"];
    [editMenu addItem:[NSMenuItem separatorItem]];
    [editMenu addItemWithTitle:@"Cortar" action:@selector(cut:) keyEquivalent:@"x"];
    [editMenu addItemWithTitle:@"Copiar" action:@selector(copy:) keyEquivalent:@"c"];
    [editMenu addItemWithTitle:@"Pegar" action:@selector(paste:) keyEquivalent:@"v"];
    [editMenu addItemWithTitle:@"Seleccionar Todo" action:@selector(selectAll:) keyEquivalent:@"a"];
    editMenuItem.submenu = editMenu;
    [menuBar addItem:editMenuItem];

    [NSApp setMainMenu:menuBar];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if (webView == self.printWebView) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSPrintInfo *printInfo = [NSPrintInfo sharedPrintInfo];
            [printInfo setTopMargin:10];
            [printInfo setBottomMargin:10];
            [printInfo setLeftMargin:10];
            [printInfo setRightMargin:10];
            [printInfo setHorizontalPagination:NSPrintingPaginationModeFit];
            [printInfo setVerticalPagination:NSPrintingPaginationModeAutomatic];
            NSPrintOperation *op = [webView printOperationWithPrintInfo:printInfo];
            op.showsPrintPanel = YES;
            op.showsProgressPanel = YES;
            [op runOperationModalForWindow:self.window delegate:nil didRunSelector:nil contextInfo:nil];
        });
        return;
    }

    if (webView == self.webView) {
        NSString *saved = loadSavedData();
        if (saved) {
            NSString *escaped = [saved stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
            escaped = [escaped stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
            escaped = [escaped stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
            escaped = [escaped stringByReplacingOccurrencesOfString:@"\r" withString:@""];
            NSString *js = [NSString stringWithFormat:@"loadFromNative('%@');", escaped];
            [self.webView evaluateJavaScript:js completionHandler:nil];
        }
        // Send backup dir path to JS
        NSString *bdir = backupDir();
        NSString *js2 = [NSString stringWithFormat:@"window._nativeBackupDir='%@';", bdir];
        [self.webView evaluateJavaScript:js2 completionHandler:nil];
    }
}

- (void)userContentController:(WKUserContentController *)controller
      didReceiveScriptMessage:(WKScriptMessage *)message {
    if (![message.name isEqualToString:@"cpp"]) return;

    NSString *body = message.body;
    NSData *data = [body dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    NSString *action = json[@"action"];

    if ([action isEqualToString:@"save"]) {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json[@"data"] options:0 error:nil];
        NSString *jsonStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        [jsonStr writeToFile:dataFilePath() atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
    else if ([action isEqualToString:@"print"]) {
        NSString *htmlContent = json[@"html"];
        if (htmlContent) {
            WKWebViewConfiguration *pc = [[WKWebViewConfiguration alloc] init];
            self.printWebView = [[WKWebView alloc] initWithFrame:NSMakeRect(0,0,700,900) configuration:pc];
            self.printWebView.navigationDelegate = self;
            [self.printWebView loadHTMLString:htmlContent baseURL:nil];
        }
    }
    else if ([action isEqualToString:@"backup"]) {
        // Save backup with timestamp
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        [fmt setDateFormat:@"yyyy-MM-dd_HHmmss"];
        NSString *ts = [fmt stringFromDate:[NSDate date]];
        NSString *label = json[@"label"] ?: @"manual";
        NSString *filename = [NSString stringWithFormat:@"backup_%@_%@.json", label, ts];
        NSString *path = [backupDir() stringByAppendingPathComponent:filename];

        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json[@"data"]
                                                          options:NSJSONWritingPrettyPrinted error:nil];
        [jsonData writeToFile:path atomically:YES];

        // Return success to JS
        NSString *js = [NSString stringWithFormat:@"backupDone('%@','%@');", filename, path];
        [self.webView evaluateJavaScript:js completionHandler:nil];
    }
    else if ([action isEqualToString:@"listBackups"]) {
        NSString *dir = backupDir();
        NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dir error:nil];
        NSMutableArray *backups = [NSMutableArray array];
        for (NSString *f in files) {
            if ([f hasSuffix:@".json"]) {
                NSString *full = [dir stringByAppendingPathComponent:f];
                NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:full error:nil];
                NSNumber *size = attrs[NSFileSize];
                NSDate *date = attrs[NSFileModificationDate];
                [backups addObject:@{@"name":f, @"size":size?:@0, @"date":[date description]?:@""}];
            }
        }
        // Sort by date desc
        [backups sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
            return [b[@"date"] compare:a[@"date"]];
        }];
        NSData *jd = [NSJSONSerialization dataWithJSONObject:backups options:0 error:nil];
        NSString *js = [NSString stringWithFormat:@"receiveBackupList(%@);",
                        [[NSString alloc] initWithData:jd encoding:NSUTF8StringEncoding]];
        [self.webView evaluateJavaScript:js completionHandler:nil];
    }
    else if ([action isEqualToString:@"restoreBackup"]) {
        NSString *filename = json[@"filename"];
        NSString *path = [backupDir() stringByAppendingPathComponent:filename];
        NSString *content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        if (content) {
            // Also save as current data
            [content writeToFile:dataFilePath() atomically:YES encoding:NSUTF8StringEncoding error:nil];
            NSString *escaped = [content stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
            escaped = [escaped stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
            escaped = [escaped stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
            escaped = [escaped stringByReplacingOccurrencesOfString:@"\r" withString:@""];
            NSString *js = [NSString stringWithFormat:@"restoreFromBackup('%@');", escaped];
            [self.webView evaluateJavaScript:js completionHandler:nil];
        }
    }
    else if ([action isEqualToString:@"deleteBackup"]) {
        NSString *filename = json[@"filename"];
        NSString *path = [backupDir() stringByAppendingPathComponent:filename];
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    else if ([action isEqualToString:@"exportFile"]) {
        // Save file to Downloads
        NSString *filename = json[@"filename"];
        NSString *content = json[@"content"];
        NSString *downloads = [NSSearchPathForDirectoriesInDomains(
            NSDownloadsDirectory, NSUserDomainMask, YES) firstObject];
        NSString *path = [downloads stringByAppendingPathComponent:filename];

        // If file exists, add number
        NSFileManager *fm = [NSFileManager defaultManager];
        if ([fm fileExistsAtPath:path]) {
            NSString *base = [filename stringByDeletingPathExtension];
            NSString *ext = [filename pathExtension];
            int i = 1;
            while ([fm fileExistsAtPath:path]) {
                path = [downloads stringByAppendingPathComponent:
                    [NSString stringWithFormat:@"%@_%d.%@", base, i++, ext]];
            }
        }
        [content writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
        NSString *js = [NSString stringWithFormat:@"exportDone('%@');",
                        [path lastPathComponent]];
        [self.webView evaluateJavaScript:js completionHandler:nil];
    }
    else if ([action isEqualToString:@"openBackupFolder"]) {
        [[NSWorkspace sharedWorkspace] openFile:backupDir()];
    }
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

@end

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        [app setActivationPolicy:NSApplicationActivationPolicyRegular];
        AppDelegate *delegate = [[AppDelegate alloc] init];
        [app setDelegate:delegate];
        [app activateIgnoringOtherApps:YES];
        [app run];
    }
    return 0;
}
