import { query, mutation } from "./_generated/server";
import { v } from "convex/values";

export const list = query({
  args: { limit: v.optional(v.number()) },
  handler: async (ctx, { limit = 50 }) => {
    return await ctx.db
      .query("transcriptions")
      .withIndex("by_created")
      .order("desc")
      .take(limit);
  },
});

export const insert = mutation({
  args: {
    text: v.string(),
    deviceId: v.string(),
    createdAt: v.number(),
    duration: v.optional(v.number()),
  },
  handler: async (ctx, args) => {
    return await ctx.db.insert("transcriptions", args);
  },
});

export const deleteRecord = mutation({
  args: { id: v.id("transcriptions") },
  handler: async (ctx, { id }) => {
    await ctx.db.delete(id);
  },
});
