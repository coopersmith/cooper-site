---
title: Vibe Coding
tags:
  - VibeCoding
  - ai
  - cursorAI
  - obsidian
---
Yesterday, I had an idea. 

I absolutely love Granola AI. It allows me to be 100% present in meetings without worrying about taking notes, but also ensures that after the meeting wraps, I have my list of action items. Its also really helpful to look back and review my previous week as I kick off the next.

But the idea of leaving my notes in Granola terrifies me. It could shut down tomorrow (I hope it doesn't) and I'd lose everything. So at the end of every day, I've been manually copying and pasting each meeting note over to Obsidian, my repository for every piece of text in my life. (I could write an entire separate post about why I love Obsidian, but it mostly comes down to Steph Ango's philosophy of [File over App](https://stephango.com/file-over-app).

So, I have a workflow that works, but its tedious and I can already feeling myself slipping in my routine. I had previously searched to see if anybody had written an Obsidian plugin, but had only come across a [blog post ](https://josephthacker.com/hacking/2025/05/08/reverse-engineering-granola-notes.html) of a guy who had written a Python script and suggested it could probably easily become an Obsidian plugin. (Side note: I love how this is 100% [A blog post is a very long and complex search query to find fascinating people and make them route interesting stuff to your inbox](https://www.henrikkarlsson.xyz/p/search-query?utm_source=substack&utm_medium=email)), another one of my favorite posts, playing out.

🚿💡 Maybe, with the help of Cursor and Claude, I could write that plugin.

I fired up Cursor, and fed it a fairly simple prompt: "I'd like to write an Obsidian plugin to import my Granola notes. To get started, you can reference this blog post about how to do it with a python script."

I wasn't expecting much. I had actually spent the previous day fighting with Claude AI to make some fairly simple tweaks to my site that I ended up just writing myself. So I was absolutely floored that after about 2-3 minutes of thinking and writing, Cursor output what turned out to be a nearly ready to ship Obsidian plugin. I spent another minute wrangling my credentials from the Granola API, input them to my new plugin, pressed the sync button, and watched all of my Granola appears magically appear in Obsidian.

I've had a lot of aha moments with AI, but this topped them all. I had gone from idea to implementation in about 20 minutes. I think this is whats known as "vibe coding" (h/t Dolapo): focusing on the intent and desired outcome rather than writing the code itself. I'm sure to many, thats a derogatory term. But for me, somebody who constantly has their ideas end in a notebook, the ability to follow through and implement it is one of the greatest jumps in my creativity I've felt in a long time. Suddenly my mind is racing with what else is possible, what else have I abandoned for lack of coding knowledge?

After the initial rush, I instantly saw some things I wanted to tweak. I spent another few hours adding and cleaning up some of the front matter, getting it more in line with my preferred formatting of my other notes in Obsidian. These refinements took much longer than the initial code, but again, were mostly done through Vibe Coding. Describing what I'm trying to accomplish with just enough knowledge and context of whats happening in the code, markdown, etc. to help guide the LLM. 

I've got it to a pretty good 1.0. Its mostly built around my very specific needs and formatting preferences (which is fine, an Obsidian plugin can be a [home cooked meal](https://www.robinsloan.com/notes/home-cooked-app/)). But I already have ideas about how to make this more generic and something that might be valuable to more people. I'll probably continue to refine it in that way, but for my purposes, its ready to go. 

If you want to kick the tires, you can clone [the repo](https://github.com/coopersmith/GranolaObsidian?tab=readme-ov-file) and try it out — or fork it if you’ve got your own tweaks in mind.