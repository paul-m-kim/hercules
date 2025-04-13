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
const SubCommands = enum { find, update, create };

const main_parsers = .{
    .command = clap.parsers.enumeration(SubCommands),
};

const main_params = clap.parseParamsComptime(
    \\-h, --help  Display this help and exit.
    \\<command>
    \\
);

const MainArgs = clap.ResultEx(clap.Help, &main_params, main_parsers);

const api_endpoint_jira_issue = "/rest/api/3/issue/";

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    // std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // important for later perhaps.
    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    // const stdout_file = std.io.getStdOut().writer();
    // var bw = std.io.bufferedWriter(stdout_file);
    // const stdout = bw.writer();
    // try stdout.print("Run `zig build test` to run the tests.\n", .{});
    // try bw.flush(); // Don't forget to flush!

    // read config
    const file_config = try std.fs.openFileAbsolute("/home/pkim/.hercules.toml", .{ .mode = .read_only });
    defer file_config.close();

    var gp_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gp_allocator_ifce = gp_allocator.allocator();
    defer _ = gp_allocator.deinit();

    var iter = try std.process.ArgIterator.initWithAllocator(gp_allocator_ifce);
    defer iter.deinit();
    _ = iter.next();

    const params = comptime clap.parseParamsComptime(
        \\-h, --help  display this help and exit.
        \\-c, --config-file <str> path to get config
        \\-j, --jira-subdomain <str>
        \\-u, --username <str>
        \\-k, --api-key <str>
    );

    const res = clap.parse(clap.Help, &params, clap.parsers.default, .{ .allocator = gp_allocator_ifce }) catch |err| {
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0)
        std.debug.print("--help\n", .{});

    const command = res.positionals[0] orelse return error.MissingCommand;
    switch (command) {
        .help => std.debug.print("--help\n", .{}),
        .find => try findMain(gp_allocator_ifce, &iter, res),
        .update => try updateMain(gp_allocator_ifce, &iter, res),
        .create => try createMain(gp_allocator_ifce, &iter, res),
    }

    // const allocator = std.heap.page_allocator();
    // var client = std.http.Client(.{ .allocator = allocator });
    // defer client.deinit();
}

fn findMain(gpa: std.mem.Allocator, iter: *std.process.ArgIterator, main_args: MainArgs) !void {
    // The parent arguments are not used here, but there are cases where it might be useful, so
    // this example shows how to pass the arguments around.
    _ = main_args;

    // The parameters for the subcommand.
    const params = comptime clap.parseParamsComptime(
        \\-h, --help  Display this help and exit.
        \\-a, --assignee <str>
        \\-p, --project <str>
        \\-s, --status <str>
        \\-i, --priority <str>
        \\-v, --version <str>
        \\
    );

    // Here we pass the partially parsed argument iterator.
    var diag = clap.Diagnostic{};
    var res = clap.parseEx(clap.Help, &params, clap.parsers.default, iter, .{
        .diagnostic = &diag,
        .allocator = gpa,
    }) catch |err| {
        diag.report(std.io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0)
        std.debug.print("--help\n", .{});
}

fn updateMain(gpa: std.mem.Allocator, iter: *std.process.ArgIterator, main_args: MainArgs) !void {
    // The parent arguments are not used here, but there are cases where it might be useful, so
    // this example shows how to pass the arguments around.
    _ = main_args;

    // The parameters for the subcommand.
    const params = comptime clap.parseParamsComptime(
        \\-h, --help  Display this help and exit.
        \\-s, --status <str>
        \\-c, --comments <str>
        \\-p, --priority <str>
        \\
    );

    // Here we pass the partially parsed argument iterator.
    var diag = clap.Diagnostic{};
    var res = clap.parseEx(clap.Help, &params, clap.parsers.default, iter, .{
        .diagnostic = &diag,
        .allocator = gpa,
    }) catch |err| {
        diag.report(std.io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0)
        std.debug.print("--help\n", .{});
}

fn createMain(gpa: std.mem.Allocator, iter: *std.process.ArgIterator, main_args: MainArgs) !void {
    // The parent arguments are not used here, but there are cases where it might be useful, so
    // this example shows how to pass the arguments around.
    _ = main_args;

    // The parameters for the subcommand.
    const params = comptime clap.parseParamsComptime(
        \\-h, --help  Display this help and exit.
        \\
    );

    // Here we pass the partially parsed argument iterator.
    var diag = clap.Diagnostic{};
    var res = clap.parseEx(clap.Help, &params, clap.parsers.default, iter, .{
        .diagnostic = &diag,
        .allocator = gpa,
    }) catch |err| {
        diag.report(std.io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0)
        std.debug.print("--help\n", .{});
}

// test "simple test" {
//     var list = std.ArrayList(i32).init(std.testing.allocator);
//     defer list.deinit(); // Try commenting this out and see if zig detects the memory leak!
//     try list.append(42);
//     try std.testing.expectEqual(@as(i32, 42), list.pop());
// }

// test "use other module" {
//     try std.testing.expectEqual(@as(i32, 150), lib.add(100, 50));
// }

// test "fuzz example" {
//     const Context = struct {
//         fn testOne(context: @This(), input: []const u8) anyerror!void {
//             _ = context;
//             // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
//             try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
//         }
//     };
//     try std.testing.fuzz(Context{}, Context.testOne, .{});
// }

const std = @import("std");
const clap = @import("clap");
const vaxis = @import("vaxis");

/// This imports the separate module containing `root.zig`. Take a look in `build.zig` for details.
const lib = @import("hercules_lib");
