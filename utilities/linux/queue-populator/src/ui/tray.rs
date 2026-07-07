//! StatusNotifierItem tray via ksni — replaces the macOS status bar/menu.
//! Icon color reflects app state; menu mirrors StatusBarController.swift.

use crossbeam_channel::Sender;

use crate::coordinator::CoordinatorMsg;
use crate::state_machine::AppState;

/// Simplified state shown in the tray.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TrayState {
    Idle,
    Recording,
    Processing,
    Review,
    Paused,
}

impl TrayState {
    pub fn from_app_state(state: &AppState) -> Self {
        match state {
            AppState::Idle => TrayState::Idle,
            AppState::Recording | AppState::Revising(_) => TrayState::Recording,
            AppState::Processing => TrayState::Processing,
            AppState::MemoReview(_) | AppState::Review(_) => TrayState::Review,
        }
    }

    fn color(self) -> (u8, u8, u8) {
        match self {
            TrayState::Idle => (0x8a, 0x8a, 0x8a),      // gray
            TrayState::Recording => (0xe0, 0x4a, 0x3a), // red
            TrayState::Processing => (0xe8, 0xa8, 0x2e), // amber
            TrayState::Review => (0x3a, 0x86, 0xe0),    // blue
            TrayState::Paused => (0x50, 0x50, 0x50),    // dark gray
        }
    }
}

pub struct QueuePopulatorTray {
    pub state: TrayState,
    pub paused: bool,
    pub coordinator: Sender<CoordinatorMsg>,
    /// Signals the egui side to show the main window.
    pub show_window: Sender<()>,
}

/// Draw a filled circle "mic dot" as an ARGB32 pixmap.
fn icon_pixels(size: i32, (r, g, b): (u8, u8, u8)) -> Vec<u8> {
    let mut data = Vec::with_capacity((size * size * 4) as usize);
    let center = (size as f32 - 1.0) / 2.0;
    let radius = size as f32 * 0.38;
    let ring = size as f32 * 0.46;
    for y in 0..size {
        for x in 0..size {
            let dx = x as f32 - center;
            let dy = y as f32 - center;
            let dist = (dx * dx + dy * dy).sqrt();
            let (a, cr, cg, cb) = if dist <= radius {
                (0xff, r, g, b)
            } else if dist <= ring {
                (0x60, r, g, b)
            } else {
                (0, 0, 0, 0)
            };
            data.extend_from_slice(&[a, cr, cg, cb]); // ARGB32 network byte order
        }
    }
    data
}

impl ksni::Tray for QueuePopulatorTray {
    fn id(&self) -> String {
        "queue-populator".into()
    }

    fn title(&self) -> String {
        format!("Queue Populator — {:?}", self.state)
    }

    fn icon_pixmap(&self) -> Vec<ksni::Icon> {
        let state = if self.paused { TrayState::Paused } else { self.state };
        [22, 32, 48]
            .into_iter()
            .map(|size| ksni::Icon {
                width: size,
                height: size,
                data: icon_pixels(size, state.color()),
            })
            .collect()
    }

    fn menu(&self) -> Vec<ksni::MenuItem<Self>> {
        use ksni::menu::*;
        vec![
            StandardItem {
                label: "Show Transcript".into(),
                activate: Box::new(|tray: &mut Self| {
                    let _ = tray.show_window.send(());
                }),
                ..Default::default()
            }
            .into(),
            CheckmarkItem {
                label: "Pause Listening".into(),
                checked: self.paused,
                activate: Box::new(|tray: &mut Self| {
                    let _ = tray.coordinator.send(CoordinatorMsg::TogglePause);
                }),
                ..Default::default()
            }
            .into(),
            MenuItem::Separator,
            StandardItem {
                label: "Quit".into(),
                activate: Box::new(|tray: &mut Self| {
                    let _ = tray.coordinator.send(CoordinatorMsg::Quit);
                }),
                ..Default::default()
            }
            .into(),
        ]
    }
}
