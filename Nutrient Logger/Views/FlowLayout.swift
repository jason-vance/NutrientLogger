//
//  FlowLayout.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/29/26.
//

import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: result.proposals[index]
            )
        }
    }

    private struct LayoutResult {
        var size: CGSize
        var positions: [CGPoint]
        var proposals: [ProposedViewSize]
    }

    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> LayoutResult {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var proposals: [ProposedViewSize] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            var size = subview.sizeThatFits(.unspecified)
            var itemProposal = ProposedViewSize.unspecified
            // Too wide for a whole row: give it the row's width so it truncates or wraps
            // instead of running past the edge.
            if size.width > maxWidth {
                itemProposal = ProposedViewSize(width: maxWidth, height: nil)
                size = subview.sizeThatFits(itemProposal)
            }
            proposals.append(itemProposal)

            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalHeight = y + rowHeight
        }

        return LayoutResult(
            size: CGSize(width: maxWidth, height: totalHeight),
            positions: positions,
            proposals: proposals
        )
    }
}
