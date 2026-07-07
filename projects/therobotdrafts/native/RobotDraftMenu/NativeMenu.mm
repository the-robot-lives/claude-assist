// Native macOS menu bar for The Robot Draft.
// Builds File / Edit / View menus in the real NSApp main menu and routes clicks back to Unity
// through a C function-pointer callback (the C# side enqueues the command id and runs it on the
// Unity main thread). Compiled to Assets/Plugins/macOS/RobotDraftMenu.bundle (see build.sh).
//
// Command ids are shared with NativeMacMenu.cs — keep them in sync.
#import <Cocoa/Cocoa.h>

typedef void (*RDCommandCallback)(int cmd);
static RDCommandCallback gCallback = NULL;
static BOOL gInstalled = NO;

@interface RDMenuTarget : NSObject
@end
@implementation RDMenuTarget
- (void)rdFire:(id)sender {
    if (gCallback && [sender isKindOfClass:[NSMenuItem class]]) {
        gCallback((int)((NSMenuItem *)sender).tag);
    }
}
// Keep every routed item always enabled (Unity, not the responder chain, owns these actions).
- (BOOL)validateMenuItem:(NSMenuItem *)item { return YES; }
@end

static RDMenuTarget *gTarget = nil;

static void RDAdd(NSMenu *menu, NSString *title, int tag, NSString *key, NSEventModifierFlags mods) {
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:@selector(rdFire:) keyEquivalent:key];
    item.target = gTarget;
    item.tag = tag;
    if (key.length > 0) item.keyEquivalentModifierMask = mods;
    [menu addItem:item];
}

// Return the existing submenu with this title, or create + insert a new one at the given index.
static NSMenu *RDEnsure(NSMenu *main, NSString *title, NSInteger index) {
    for (NSMenuItem *mi in main.itemArray) {
        if ([mi.title isEqualToString:title] && mi.hasSubmenu) return mi.submenu;
    }
    NSMenuItem *holder = [[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
    NSMenu *sub = [[NSMenu alloc] initWithTitle:title];
    holder.submenu = sub;
    if (index >= 0 && index <= main.numberOfItems) [main insertItem:holder atIndex:index];
    else [main addItem:holder];
    return sub;
}

extern "C" void RDInstallMenu(RDCommandCallback cb) {
    gCallback = cb;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (gInstalled) return;
        gInstalled = YES;
        if (gTarget == nil) gTarget = [[RDMenuTarget alloc] init];

        NSMenu *main = [NSApp mainMenu];
        if (main == nil) { main = [[NSMenu alloc] init]; [NSApp setMainMenu:main]; }

        NSInteger at = main.numberOfItems > 0 ? 1 : 0; // after the app menu

        NSMenu *file = RDEnsure(main, @"File", at);
        RDAdd(file, @"New",          1, @"n", NSEventModifierFlagCommand);
        RDAdd(file, @"Open…",        2, @"o", NSEventModifierFlagCommand);
        [file addItem:[NSMenuItem separatorItem]];
        RDAdd(file, @"Save",         3, @"s", NSEventModifierFlagCommand);
        RDAdd(file, @"Save As…",     4, @"s", NSEventModifierFlagCommand | NSEventModifierFlagShift);
        [file addItem:[NSMenuItem separatorItem]];
        RDAdd(file, @"Export Code…", 5, @"",  0);

        NSMenu *edit = RDEnsure(main, @"Edit", at + 1);
        RDAdd(edit, @"Undo",   10, @"z", NSEventModifierFlagCommand);
        RDAdd(edit, @"Redo",   11, @"z", NSEventModifierFlagCommand | NSEventModifierFlagShift);
        [edit addItem:[NSMenuItem separatorItem]];
        RDAdd(edit, @"Copy",   12, @"c", NSEventModifierFlagCommand);
        RDAdd(edit, @"Paste",  13, @"v", NSEventModifierFlagCommand);
        RDAdd(edit, @"Delete", 14, @"",  0);

        NSMenu *view = RDEnsure(main, @"View", at + 2);
        RDAdd(view, @"Frame All",       20, @"f", NSEventModifierFlagCommand);
        RDAdd(view, @"Cycle Nav Mode",  21, @"",  0);
        RDAdd(view, @"Toggle 2D / 3D",  22, @"",  0);
    });
}
