# MJML - FIM Solution Documentation

## Description
[MJML](https://mjml.io) is a markup language that compiles to responsive, email-client-safe HTML. It abstracts away the table-based hacks and inline-CSS quirks required for reliable rendering across Gmail, Outlook, Apple Mail, and others — the practical way to produce newsletter and transactional email for a Substack/newsletter funnel.

## Basic Syntax
```xml
<mjml>
  <mj-body background-color="#f4f4f4">
    <mj-section>
      <mj-column>
        <mj-text font-size="22px" font-weight="700">Rate Limiting 101</mj-text>
        <mj-text>Token buckets, leaky buckets, and sliding windows.</mj-text>
        <mj-button href="https://example.com/post" background-color="#111">
          Read the full post
        </mj-button>
        <mj-image src="https://example.com/diagram.png" alt="diagram" />
      </mj-column>
    </mj-section>
  </mj-body>
</mjml>
```

## Toolchain
- **mjml** (CLI/Node) - `mjml in.mjml -o out.html`
- **mjml-react** / **mrml** (Rust) - Programmatic and fast server-side rendering
- **Handlebars/Liquid** - Templating for personalization before compile
- **Email service APIs** - SendGrid, Postmark, Mailgun for delivery
- **Litmus / Email on Acid** - Cross-client render testing

## Strengths
- Produces robust responsive HTML that survives Outlook/Gmail quirks
- High-level components (sections, columns, buttons) vs raw email tables
- Consistent rendering across major email clients
- Templating-friendly for personalized newsletters at scale
- Integrates with transactional/ESP delivery pipelines

## Limitations
- Compilation step required (not hand-edited final HTML)
- Constrained to MJML's component set for layout
- Still must test in real clients for edge cases
- Not for general web pages — email-specific

## Best Use Cases
- Newsletter issues for Substack/owned-list distribution
- Transactional emails (welcome, receipts, drip sequences)
- Article-announcement broadcasts with CTAs
- Templated, personalized email at scale

## NPL-FIM Integration
```npl
⌜mjml-email|mjml|FIM@1.0⌝
format: mjml
compile: mjml-cli | mrml
template: handlebars | liquid
deliver: sendgrid | postmark
output: responsive-email-html
⌞mjml-email⌟
```

NPL agents emit MJML when the deliverable is an email — newsletter or transactional — compiling to client-safe HTML for an ESP.
