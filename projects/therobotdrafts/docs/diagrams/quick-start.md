# Quick Start Guide: TheRobotDrafts Example Diagrams

Get started with example diagrams in 5 minutes!

---

## 1. Find an Example (30 seconds)

### Option A: Browse by Category
1. Open the [main index](index.md)
2. Click on a diagram family (e.g., "Tier 1: Class Diagram")
3. Scan examples by complexity (🟢 Simple, 🟡 Medium, 🔴 Complex)

### Option B: Use the Complexity Matrix
1. Go to [Complexity Matrix](index.md#complexity-matrix) in the main index
2. Find your diagram type row
3. Click the checkmark for desired complexity level

### Option C: Domain Search
1. Use the [Domain Search](index.md#domain-search) section
2. Pick your industry/use case (e.g., "Web Applications")
3. Browse recommended examples

---

## 2. Preview & Understand (1 minute)

Each example includes:
- **📋 Description**: What this diagram demonstrates and teaches
- **🎯 Use Case**: When to use this pattern
- **📊 Structure**: Key elements and relationships
- **💡 Tips**: Important considerations and variations

**Example Preview:**
> **Class Diagram - Simple Banking Domain** (🟢 Simple)
> 
> Demonstrates basic UML class relationships: Customer, Account, and Transaction classes with clear inheritance and associations. Perfect for learning fundamental UML concepts.

**Check the Legend:**
- 🟢 **Simple**: 3-7 elements, educational focus
- 🟡 **Medium**: 8-15 elements, realistic scenario  
- 🔴 **Complex**: 16+ elements, production patterns

---

## 3. Clone the Example (30 seconds)

### Method A: Single Click Clone
1. Click the **"Clone This Example"** button on any example page
2. The diagram opens in your TheRobotDrafts workspace
3. It's automatically saved as `[original-name]-copy.puml`

### Method B: Copy-Paste
1. Click **"Copy PlantUML Code"** on the example page
2. Create a new diagram in TheRobotDrafts
3. Paste the code (Ctrl/Cmd + V)
4. Save with your preferred name

### Method C: Download
1. Click the **"Download .puml"** button
2. Open the file in TheRobotDrafts
3. File automatically renders in the editor

---

## 4. Customize for Your Needs (2 minutes)

### Common Customizations:

**🔄 Rename Elements**
```plantuml
' Before
class Account {
  -balance: decimal
  +deposit(amount: decimal): void
}

' After - Your domain
class ShoppingCart {
  -items: List<Item>
  +addItem(item: Item): void
  +calculateTotal(): decimal
}
```

**➕ Add Elements**
- Right-click existing element → "Add Related"
- Type new element name → Select type (class, interface, etc.)
- Position using drag-drop

**🔗 Change Relationships**
- Click relationship line → Select new type (association, inheritance, etc.)
- Drag endpoint to different element
- Update multiplicity (1..*, 0..1, etc.)

**🎨 Adjust Styling**
- Select element → Properties panel
- Change color, size, or label position
- Apply theme from library

---

## 5. Advanced: Use Variants for Specific Patterns

Each diagram type includes **variants** that show different approaches:

### Class Diagram Variants Example:
- **🎯 Interface-focused**: Shows system contracts and API boundaries
- **🔄 Inheritance-heavy**: Demonstrates polymorphism and abstract classes  
- **🏗️ Composition patterns**: "Has-a" relationships and object lifecycle

**How to use variants:**
1. Navigate to the main diagram type page
2. Scroll down to "Variants" section
3. Preview each variant's approach
4. Clone the variant that matches your design intent

---

## 6. Export & Share Your Diagram

### Export Options:
- **PlantUML** (.puml) - Source format, editable
- **XMI** (.xmi) - UML model interchange (Sparx EA, etc.)
- **Mermaid** (.mmd) - GitHub-friendly format
- **SVG/PNG** - Graphics for documentation
- **PDF** - Print-ready format

### Sharing:
- **Link**: Share TheRobotDrafts workspace link for collaborative editing
- **Embed**: Embed SVG in markdown/HTML documentation
- **Print**: Export to PDF for presentations

---

## Workflows By Scenario

### "I need to model a new API"
1. Browse → **Sequence Diagram** → **Medium: REST API**
2. Clone and rename to your endpoints
3. Update endpoints and methods
4. Add error handling flows
5. Export as PNG for API documentation

### "I need to document a business process"
1. Browse → **BPMN Process** → **Medium: Order Processing**
2. Clone and replace with your business steps
3. Update actors and swimlanes
4. Add decision gates and exception flows
5. Export SVG for stakeholder review

### "I need to design database schema"
1. Browse → **ERD/Data Model** → **Simple: Blog Schema**
2. Clone and add your tables
3. Define relationships (PK/FK, cardinality)
4. Add constraints and indexes
5. Generate DDL from model

### "I need to show system architecture"
1. Browse → **Component Diagram** → **Medium: Layered System**
2. Clone and arrange your services
3. Define interfaces and dependencies
4. Add deployment considerations
5. Export XMI for import into other EA tools

---

## Troubleshooting

**❌ "My diagram doesn't render":**
- Check PlantUML syntax using the built-in validator
- Ensure all relationships have proper endpoints
- Verify element names don't have special characters

**❌ "Clone button doesn't work":**
- Try Method B (copy-paste) or Method C (download)
- Check browser console for errors
- Ensure you're logged into TheRobotDrafts

**❌ "Customization broke something":**
- Use **"Undo"** (Ctrl/Cmd + Z) to step back
- Check the example file for original structure
- Re-clone from the example and start over

---

## Learning Path

### Week 1: Fundamentals
- Day 1-2: Try all Tier 1 **Simple** examples
- Day 3-4: Customize 2 Simple examples for your domain  
- Day 5: Explore Tier 1 **Medium** examples

### Week 2: Patterns & Complexity
- Day 1-3: Work through **Medium** complexity examples
- Day 4-5: Experiment with **variants** and design patterns

### Week 3: Advanced & Enterprise
- Day 1-3: Explore Tier **Complex** examples
- Day 4-5: Try Tier 2/3 diagrams relevant to your work

---

## Next Steps

✅ **Ready to start?** Browse the [main index](index.md) and find your first example!

📚 **Want to learn more?** Check out the [Pattern Library](patterns/) for common design patterns.

💡 **Need inspiration?** Browse [Community Examples](community/) to see what others have created.

**Pro Tip**: Bookmark the examples index for quick access when starting new diagrams!  

---

*Last Updated: 2026-07-08 | Version: 1.0.0*