import { test } from "node:test";
import assert from "node:assert/strict";
import {
    pageLifecycle, pageNeedsKeyboard, pagePopupTimeout,
    pushCall, popCall, topOfCall, CALL_STACK_LIMIT,
} from "../../core/config-shape.mjs";

test("pageLifecycle defaults to called when a page declares nothing", () => {
    assert.equal(pageLifecycle({}), "called");
    assert.equal(pageLifecycle(undefined), "called");
});

test("pageLifecycle reads what the page declares", () => {
    assert.equal(pageLifecycle({ lifecycle: "popup" }), "popup");
    assert.equal(pageLifecycle({ lifecycle: "lock" }), "lock");
});

test("pageNeedsKeyboard defaults to false", () => {
    assert.equal(pageNeedsKeyboard({}), false);
    assert.equal(pageNeedsKeyboard({ needsKeyboard: true }), true);
});

test("pagePopupTimeout defaults to 5000ms", () => {
    assert.equal(pagePopupTimeout({}), 5000);
    assert.equal(pagePopupTimeout({ popupTimeout: 2000 }), 2000);
});

test("pushCall grows the stack, most recent last", () => {
    assert.deepEqual(pushCall(undefined, "a"), ["a"]);
    assert.deepEqual(pushCall(["a"], "b"), ["a", "b"]);
});

test("pushCall keeps only the last 5 entries", () => {
    let stack = [];
    for (let i = 0; i < 8; i++) stack = pushCall(stack, `p${i}`);
    assert.equal(stack.length, CALL_STACK_LIMIT);
    assert.deepEqual(stack, ["p3", "p4", "p5", "p6", "p7"]);
});

test("popCall drops the top entry, oldest-first order preserved", () => {
    assert.deepEqual(popCall(["a", "b", "c"]), ["a", "b"]);
    assert.deepEqual(popCall(["a"]), []);
    assert.deepEqual(popCall([]), []);
    assert.deepEqual(popCall(undefined), []);
});

test("topOfCall is the most recently called page, or empty when idle", () => {
    assert.equal(topOfCall(["a", "b"]), "b");
    assert.equal(topOfCall([]), "");
    assert.equal(topOfCall(undefined), "");
});

test("unstacking in reverse order lands back on idle (empty) once exhausted", () => {
    let stack = pushCall(pushCall(pushCall([], "a"), "b"), "c");
    assert.equal(topOfCall(stack), "c");
    stack = popCall(stack);
    assert.equal(topOfCall(stack), "b");
    stack = popCall(stack);
    assert.equal(topOfCall(stack), "a");
    stack = popCall(stack);
    assert.equal(topOfCall(stack), "");
});
