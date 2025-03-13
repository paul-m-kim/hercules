//! By convention, main.zig is where your main function lives in the case that
//! you are building an executable. If you are making a library, the convention
//! is to delete this file and start with root.zig instead.

/// Jira REST APIs:
/// https://developer.atlassian.com/cloud/jira/platform/rest/v3/intro/#version
/// Get JQL Search:              GET  /rest/api/3/search/jql
/// https://support.atlassian.com/jira-service-management-cloud/docs/use-advanced-search-with-jira-query-language-jql/
/// useful fields:
/// - reporter = John Smith
/// - assignee = John Smith
/// - project = Name
/// - issuetype = Type
/// - status = Status
/// - comment
/// - created
/// - description
/// - fixVersion
/// - type
/// - reporter
/// - priority
/// - labels
/// - due
/// - parent
/// - updated
/// "keywords":
/// - AND
/// - OR
/// - NOT
/// - EMPTY
/// - NULL - same as empty
/// - ORDER BY
/// ops:
/// - '='
/// - '!='
/// - '>'
/// - '>='
/// - '<'
/// - '<='
/// - in
/// - not in
/// - '~' (contains)
/// - '!~' (does not contain)
/// - is
/// - is not
/// - was
/// - was in
/// - was not in
/// - was not
/// - changed
/// functions:
/// - approved()SLA?
/// - approver()SLA?
/// - completed()SLA?
/// - currentLogin()
/// - currentUser()
/// - endOfDay()
/// - endOfWeek()
/// - endOfMonth()
/// - endOfYear()
/// - linkedIssue
/// - linkedIssues()
/// - myApproval()
/// - myPendingApproval()
/// - myPending()
/// - now()
/// - openSprints()
/// - paused()SLA?
/// - pending()SLA?
/// - pendingBy()SLA?
/// - releasedVersions()
/// - remaining()SLA?
/// - running()SLA?
/// - startOfDay()
/// - startOfWeek()
/// - startOfMonth()
/// - startOfYear()
/// - subtaskIssueTypes()
/// - unreleasedVersions()
/// - updatedBy()
///
/// Get Project:                 GET  /rest/api/3/project/{idOrKey}
/// Get Version:                 GET  /rest/api/3/version/{id}
/// Get Issue:                   GET  /rest/api/3/issue/{idOrKey}
/// Put Assign Issue:            PUT  /rest/api/3/issue/{idOrKey}/assignee
/// Get Issue Comments:          GET  /rest/api/3/issue/{idOrKey}/comment
/// Get Issue Comment:           GET  /rest/api/3/issue/{idOrKey}/comment/{id}
/// Post Add Issue Comment:      POST /rest/api/3/issue/{idOrKey}/comment
/// Put Update Issue Comment:    PUT  /rest/api/3/issue/{idOrKey}/comment/{id}
/// Del Delete Issue Comment:    DEL  /rest/api/3/issue/{idOrKey}/comment/{id}
/// Get Statuses:                GET  /rest/api/3/statuses
/// Put Update Statuses:         PUT  /rest/api/3/statuses
/// Get Status:                  GET  /rest/api/3/status/{idOrName}
/// Get Priority (?):            GET  /rest/api/3/priority/{id}
///
pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // Don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // Try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "use other module" {
    try std.testing.expectEqual(@as(i32, 150), lib.add(100, 50));
}

test "fuzz example" {
    const Context = struct {
        fn testOne(context: @This(), input: []const u8) anyerror!void {
            _ = context;
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(Context{}, Context.testOne, .{});
}

const std = @import("std");
const clap = @import("clap");
const vaxis = @import("vaxis");

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const lib = @import("hercules_lib");
