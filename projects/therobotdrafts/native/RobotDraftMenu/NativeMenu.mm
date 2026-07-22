// Native macOS menu bar for The Robot Draft — nav-redesign IA v2 (clean-room).
// Builds File / Edit / Model / Diagram / Code / Go / View menus in the real NSApp main menu and
// routes clicks back to Unity through a C function-pointer callback (the C# side enqueues the
// command id and runs it on the Unity main thread). Compiled to
// Assets/Plugins/macOS/RobotDraftMenu.bundle (see build.sh).
//
// Command ids are shared with NativeMacMenu.cs — keep them in sync. Ids are grouped by menu
// (File 1xx, Edit 2xx, Model 3xx, Diagram 4xx, Code 5xx, Go 6xx, View 7xx); the legacy 1–22 ids
// remain valid on the C# side but are no longer emitted here.
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

// A disabled, unrouted submenu holder inside a menu.
static NSMenu *RDSub(NSMenu *menu, NSString *title) {
    NSMenuItem *holder = [[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
    NSMenu *sub = [[NSMenu alloc] initWithTitle:title];
    holder.submenu = sub;
    [menu addItem:holder];
    return sub;
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
        NSEventModifierFlags cmd = NSEventModifierFlagCommand;
        NSEventModifierFlags cmdShift = NSEventModifierFlagCommand | NSEventModifierFlagShift;
        NSEventModifierFlags cmdOpt = NSEventModifierFlagCommand | NSEventModifierFlagOption;

        // ------------------------------------------------------------------ File
        NSMenu *file = RDEnsure(main, @"File", at);
        RDAdd(file, @"New Model",        100, @"n", cmd);
        RDAdd(file, @"Open…",            101, @"o", cmd);
        [file addItem:[NSMenuItem separatorItem]];
        RDAdd(file, @"Save",             102, @"s", cmd);
        RDAdd(file, @"Save As…",         103, @"s", cmdShift);
        [file addItem:[NSMenuItem separatorItem]];
        NSMenu *fImport = RDSub(file, @"Import");
        RDAdd(fImport, @"PlantUML…",                 110, @"", 0);
        RDAdd(fImport, @"XMI…",                      111, @"", 0);
        RDAdd(fImport, @"Mermaid…",                  112, @"", 0);
        RDAdd(fImport, @"EA Project (.qea)…",        113, @"", 0);
        [fImport addItem:[NSMenuItem separatorItem]];
        RDAdd(fImport, @"Source Code…",              114, @"", 0);
        RDAdd(fImport, @"From Image…",               115, @"", 0);
        RDAdd(fImport, @"Database Schema…",          116, @"", 0);
        NSMenu *fExport = RDSub(file, @"Export");
        RDAdd(fExport, @"PlantUML…",                 120, @"", 0);
        RDAdd(fExport, @"XMI…",                      121, @"", 0);
        RDAdd(fExport, @"Mermaid…",                  122, @"", 0);
        RDAdd(fExport, @"EA Project (.qea)…",        123, @"", 0);
        [fExport addItem:[NSMenuItem separatorItem]];
        RDAdd(fExport, @"Copy View as PNG",          124, @"c", cmdOpt);
        RDAdd(fExport, @"3D Scene (OBJ + MTL)…",     125, @"", 0);
        RDAdd(fExport, @"3D Scene (JSON vertices)…", 126, @"", 0);

        // ------------------------------------------------------------------ Edit
        NSMenu *edit = RDEnsure(main, @"Edit", at + 1);
        RDAdd(edit, @"Undo",   200, @"z", cmd);
        RDAdd(edit, @"Redo",   201, @"z", cmdShift);
        [edit addItem:[NSMenuItem separatorItem]];
        RDAdd(edit, @"Copy",   202, @"c", cmd);
        RDAdd(edit, @"Paste",  203, @"v", cmd);
        RDAdd(edit, @"Delete", 204, @"", 0);

        // ------------------------------------------------------------------ Model
        NSMenu *model = RDEnsure(main, @"Model", at + 2);
        NSMenu *mAdd = RDSub(model, @"Add Element");
        RDAdd(mAdd, @"Class",     300, @"", 0);
        RDAdd(mAdd, @"Interface", 301, @"", 0);
        RDAdd(mAdd, @"Enum",      302, @"", 0);
        RDAdd(mAdd, @"Package",   303, @"", 0);
        RDAdd(mAdd, @"Note",      304, @"", 0);
        [model addItem:[NSMenuItem separatorItem]];
        RDAdd(model, @"Select Mode",  312, @"", 0);
        RDAdd(model, @"Connect Mode", 310, @"", 0);
        RDAdd(model, @"Place Mode",   311, @"", 0);

        // ------------------------------------------------------------------ Diagram
        NSMenu *diagram = RDEnsure(main, @"Diagram", at + 3);
        RDAdd(diagram, @"New Empty Diagram", 400, @"n", cmdShift);
        RDAdd(diagram, @"Delete Diagram…",   401, @"", 0);
        [diagram addItem:[NSMenuItem separatorItem]];
        NSMenu *dLayout = RDSub(diagram, @"Layout");
        RDAdd(dLayout, @"By Source / Package", 412, @"", 0);
        RDAdd(dLayout, @"Hierarchy",           413, @"", 0);
        RDAdd(dLayout, @"Force-Directed",      411, @"", 0);
        RDAdd(dLayout, @"Tidy Grid",           410, @"", 0);
        RDAdd(dLayout, @"AI-Assisted…",        414, @"", 0);
        [dLayout addItem:[NSMenuItem separatorItem]];
        RDAdd(dLayout, @"Sequence: Auto-Arrange", 415, @"", 0);

        // ------------------------------------------------------------------ Code
        NSMenu *code = RDEnsure(main, @"Code", at + 4);
        RDAdd(code, @"Generate Code… (wizard)", 500, @"g", cmdShift);
        RDAdd(code, @"Import Code → Elements…", 501, @"", 0);
        [code addItem:[NSMenuItem separatorItem]];
        NSMenu *cDb = RDSub(code, @"Database");
        RDAdd(cDb, @"Connect / Load Schema…",       503, @"", 0);
        RDAdd(cDb, @"Generate Liquibase Changelog…", 502, @"", 0);

        // ------------------------------------------------------------------ Go
        NSMenu *go = RDEnsure(main, @"Go", at + 5);
        RDAdd(go, @"Frame Diagram",     600, @"f", cmd);
        [go addItem:[NSMenuItem separatorItem]];
        RDAdd(go, @"Camera Z Up",       601, @"", 0);
        RDAdd(go, @"Camera Z Down",     602, @"", 0);
        RDAdd(go, @"Cycle Drag-Nav Mode", 603, @"", 0);

        // ------------------------------------------------------------------ View
        NSMenu *view = RDEnsure(main, @"View", at + 6);
        RDAdd(view, @"Toggle 2D / 3D",          700, @"", 0);
        [view addItem:[NSMenuItem separatorItem]];
        RDAdd(view, @"LLM Settings…",           702, @"", 0);
        RDAdd(view, @"Vision LLM Settings…",    703, @"", 0);
        [view addItem:[NSMenuItem separatorItem]];
        RDAdd(view, @"Help && Shortcuts…",      701, @"/", cmd);
    });
}
