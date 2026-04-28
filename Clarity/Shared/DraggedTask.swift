//
//  DraggedTask.swift
//  Clarity
//
//  Tiny Transferable wrapper used by the calendar drag-and-drop. We send
//  just the task ID across — the real mutation happens in TaskStore.move
//  on the receiving cell.
//

import Foundation
import CoreTransferable

struct DraggedTask: Transferable {
    let taskID: UUID

    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation { dragged in
            dragged.taskID.uuidString
        } importing: { string in
            DraggedTask(taskID: UUID(uuidString: string) ?? UUID())
        }
    }
}
