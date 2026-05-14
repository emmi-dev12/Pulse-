import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  transcriptions: defineTable({
    text: v.string(),
    deviceId: v.string(),
    createdAt: v.number(),
    duration: v.optional(v.number()),
  })
    .index("by_device", ["deviceId"])
    .index("by_created", ["createdAt"]),
});
