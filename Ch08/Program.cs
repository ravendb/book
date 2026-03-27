#nullable disable
#:package RavenDB.Client@7.2
#:package Spectre.Console@0.49.1

using Raven.Client.Documents;
using Raven.Client.Documents.Operations.ConnectionStrings;
using Raven.Client.Documents.Operations.AI.Agents;
using Raven.Client.Documents.AI;
using Spectre.Console;

const string ConnectionStringName = "OpenAI Generative";

using var store = new DocumentStore
{
    Urls = ["http://localhost:8080"],
    Database = "store"
};

store.Initialize();

if (await HasAiConnectionStringAsync(store) is false)
    return;

await CreateShoppingAgentAsync(store);

var companyId = "companies/1-A";
var conversation = store.AI.Conversation(
    agentId: "shopping-agent",
    conversationId: "chats/",
    new AiConversationCreationOptions()
        .AddParameter("Company", companyId)
);

// Register action handlers
conversation.Handle<AddToCartParams>("AddToCart", async args =>
{
    using var session = store.OpenAsyncSession();
    string cartId = "carts/" + companyId;
    var cart = await session.LoadAsync<ShoppingCart>(cartId);
    if (cart is null)
    {
        cart = new ShoppingCart { Items = [] };
        await session.StoreAsync(cart, cartId);
    }

    var item = cart.Items.Find(x => x.ProductId == args.ProductId);
    if (item is null)
    {
        var product = await session.LoadAsync<Product>(args.ProductId);
        item = new ShoppingCartItem
        {
            ProductId = args.ProductId,
            ProductName = product?.Name ?? args.ProductId
        };
        cart.Items.Add(item);
    }
    item.Quantity += args.Quantity;
    await session.SaveChangesAsync();
    return $"Added {args.Quantity} of {item.ProductName} to cart (total: {item.Quantity})";
});

conversation.Handle<PurchaseCartParams>("PurchaseCart", async args =>
{
    using var session = store.OpenAsyncSession();
    string cartId = "carts/" + companyId;
    var cart = await session.LoadAsync<ShoppingCart>(cartId);
    if (cart is null || cart.Items.Count == 0)
        return "Cart is empty, nothing to purchase.";

    // In a real app, you'd process payment here
    var summary = string.Join(", ", cart.Items.Select(i => $"{i.ProductName} x{i.Quantity}"));
    cart.Items.Clear();
    await session.SaveChangesAsync();
    return $"Purchase complete: {summary}";
});

conversation.Handle<ReturnMerchandiseParams>("ReturnMerchandise", async args =>
{
    using var session = store.OpenAsyncSession();
    var order = await session.LoadAsync<Order>(args.OrderId);
    if (order?.Company != companyId)
        throw new InvalidOperationException("Order not found or not for the current company");

    var ret = new Return(args.ProductId, args.OrderId, args.Reason, DateTime.UtcNow, "Pending");
    await session.StoreAsync(ret);
    await session.SaveChangesAsync();
    return $"Return started (id: {ret.Id}). We'll process it shortly.";
});

conversation.Handle<RememberThisParams>("RememberThis", async args =>
{
    using var session = store.OpenAsyncSession();
    var docId = $"Memories/{companyId}/{args.Name}";
    var mem = new Memory(args.Title, args.Description, companyId);
    await session.StoreAsync(mem, docId);
    await session.SaveChangesAsync();
    return $"Remembered: {args.Title}";
});

conversation.Handle<CreateReminderParams>("CreateReminder", async args =>
{
    using var session = store.OpenAsyncSession();
    var at = DateTime.Parse(args.At);
    var reminder = new Reminder(companyId, conversation.Id, args.ProductId, args.Msg);
    await session.StoreAsync(reminder);
    session.Advanced.GetMetadataFor(reminder)["@refresh"] = at;
    await session.SaveChangesAsync();
    return $"Reminder set for {at:yyyy-MM-dd} ({reminder.Id})";
});

AnsiConsole.Write(new Rule("[bold yellow]Shopping Agent[/]").RuleStyle("grey"));
AnsiConsole.MarkupLine("[dim]Type your message below. Press Ctrl+C to exit.[/]\n");

while (true)
{
    var userPrompt = AnsiConsole.Ask<string>("[green]You >[/]");
    if (string.IsNullOrWhiteSpace(userPrompt))
        continue;

    conversation.AddUserPrompt(userPrompt);

    ShoppingAgentAnswer answer = null;
    await AnsiConsole.Status()
        .Spinner(Spinner.Known.Dots)
        .SpinnerStyle(Style.Parse("yellow"))
        .StartAsync("Thinking...", async _ =>
        {
            var result = await conversation.RunAsync<ShoppingAgentAnswer>();
            answer = result.Answer;
        });

    AnsiConsole.Write(new Panel(Markup.Escape(answer.Reply))
        .Header("[bold cyan]Agent[/]")
        .Border(BoxBorder.Rounded)
        .BorderStyle(Style.Parse("cyan"))
        .Expand());

    await DisplayAgentExtras(store, answer);

    // If there are follow-up suggestions, let the user pick one or type freely
    if (answer.Followups is { Count: > 0 })
    {
        var choices = answer.Followups.Concat(["(type my own)"]).ToList();
        var pick = AnsiConsole.Prompt(
            new SelectionPrompt<string>()
                .Title("[dim]Suggested follow-ups:[/]")
                .HighlightStyle(Style.Parse("yellow"))
                .AddChoices(choices));

        if (pick != "(type my own)")
        {
            conversation.AddUserPrompt(pick);
            await AnsiConsole.Status()
                .Spinner(Spinner.Known.Dots)
                .SpinnerStyle(Style.Parse("yellow"))
                .StartAsync("Thinking...", async _ =>
                {
                    var result = await conversation.RunAsync<ShoppingAgentAnswer>();
                    answer = result.Answer;
                });

            AnsiConsole.Write(new Panel(Markup.Escape(answer.Reply))
                .Header("[bold cyan]Agent[/]")
                .Border(BoxBorder.Rounded)
                .BorderStyle(Style.Parse("cyan"))
                .Expand());

            await DisplayAgentExtras(store, answer);
        }
    }

    AnsiConsole.WriteLine();
}

async Task DisplayAgentExtras(IDocumentStore store, ShoppingAgentAnswer answer)
{
    using var session = store.OpenAsyncSession();
    if (answer.RelatedProducts is { Count: > 0 })
    {
        var products = await session.LoadAsync<Product>(answer.RelatedProducts);
        var table = new Table()
            .Border(TableBorder.SimpleHeavy)
            .BorderStyle(Style.Parse("green"))
            .AddColumn("[bold]Product ID[/]")
            .AddColumn("[bold]Name[/]");
        foreach (var (id, product) in products)
        {
            if (product is not null)
                table.AddRow(Markup.Escape(id), Markup.Escape(product.Name));
        }
        AnsiConsole.Write(table);
    }
    if (answer.RelatedOrders is { Count: > 0 })
    {
        AnsiConsole.MarkupLine("[bold blue]Related Orders:[/] " +
            string.Join(", ", answer.RelatedOrders.Select(o => $"[link]{Markup.Escape(o)}[/]")));
    }
}

// ── Agent creation ──────────────────────────────────────────────────

async Task CreateShoppingAgentAsync(IDocumentStore store)
{
    var aiAgent = new AiAgentConfiguration
    {
        Name = "Shopping Agent",
        Identifier = "shopping-agent",
        ConnectionStringName = ConnectionStringName,
        SystemPrompt =
            """
            Act as a savvy Shopping Assistant for Northwind e-commerce store, 
            dedicated to helping customers find exactly what they need 
            with a mix of efficiency and flair. Your goal is to provide 
            personalized product recommendations, information about past 
            orders, assist in billing and help the customers have a great day. 
            Maintain a helpful, upbeat, and professional tone—think of yourself 
            as a knowledgeable concierge who knows the inventory inside out and 
            treats every shopper like a VIP.
            """,
        SampleObject =
            """
            { 
                "Reply": "Answer to the customer",
                "RelatedProducts": ["Related products IDs"],
                "RelatedOrders": ["Related Order IDs"],
                "Followups": [
                    "Up to 3 follow-up suggestions to keep the conversation going"
                ]
            } 
            """,
        Parameters =
        [
            new AiAgentParameter("Company",
                "The id of the current company for the agent")
        ],
        Queries =
        [
            new AiAgentToolQuery
            {
                Name = "SearchProductCatalog",
                Description =
                    """
                    Search the product catalog using vector search to 
                    find matching products to the search terms
                    """,
                Query =
                    """
                    from "Products" 
                    where vector.search(embedding.text(Name), $q)
                    limit 10
                    """,
                ParametersSampleObject =
                    """
                    { "q": ["query terms for semantic search on the products"] }
                    """
            },
            new AiAgentToolQuery
            {
                Name = "GetRecentOrders",
                Description =
                    """
                    Get the recent orders for the current company
                    along with their recently ordered products
                    """,
                Query =
                    """
                    from "Orders" as o
                    where o.Company = $Company and o.ShippedAt != null
                    order by o.OrderedAt desc
                    select {
                        OrderedAt: o.OrderedAt,
                        Products: o.Lines.map(x=>({
                            Product: x.Product, 
                            ProductName: x.ProductName
                        }))
                    }
                    limit 5
                    """,
                ParametersSampleObject = "{}",
                Options = new AiAgentToolQueryOptions
                {
                    AddToInitialContext = true,
                    AllowModelQueries = true
                }
            },
            new AiAgentToolQuery
            {
                Name = "GetOrdersInDateRange",
                Description =
                    """
                    Get the orders for the current company in a specific date range.
                    """,
                Query =
                    """
                    from "Orders" as o 
                    where o.Company = $Company 
                    and o.OrderedAt between $StartDate and $EndDate
                    order by o.OrderedAt desc
                    select {
                        OrderedAt: o.OrderedAt,
                        Products: o.Lines.map(x=>({
                            Product: x.Product, 
                            ProductName: x.ProductName
                        }))
                    }
                    """,
                ParametersSampleObject =
                    """{"StartDate": "yyyy-MM-dd", "EndDate": "yyyy-MM-dd"}"""
            },
            new AiAgentToolQuery
            {
                Name = "SearchMemories",
                Description =
                    """
                    Search your memories about this customer. Returns a list of 
                    memory titles — use FetchMemory to read the full details of 
                    any memory that looks relevant.
                    """,
                Query =
                    """
                    from Memories
                    where Company = $Company
                      and vector.search(embedding.text(Description), $searchTerms)
                    select id() as Id, Title
                    limit 10
                    """,
                ParametersSampleObject =
                    """
                    { "searchTerms": "search for relevant memories" }
                    """
            },
            new AiAgentToolQuery
            {
                Name = "FetchMemory",
                Description =
                    """
                    Load the full details of a specific memory by its ID. Use 
                    this after SearchMemories to read information that looks 
                    relevant to the current conversation.
                    """,
                Query =
                    """
                    from Memories
                    where Company = $Company
                      and id() = $memoryId
                    """,
                ParametersSampleObject =
                    """
                    { "memoryId": "The id of the memory to fetch" }
                    """
            },
            new AiAgentToolQuery
            {
                Name = "GetReturnStatus",
                Description =
                    """
                    Get the status of a return process for a given order and product.
                    The agent should use this query to check the status of a return 
                    process after it has been initiated using "ReturnMerchandise".
                    """,
                Query =
                    """
                    from Returns as r
                    where r.OrderId = $OrderId and r.ProductId = $ProductId
                    """,
                ParametersSampleObject =
                    """
                    { 
                        "ProductId": "id of the product being returned",
                        "OrderId": "id of the order that contains the product"
                    }
                    """
            }
        ],
        Actions =
        [
            new AiAgentToolAction
            {
                Name = "AddToCart",
                Description = "Add a product to the user's cart",
                ParametersSampleObject =
                    """
                    {
                        "ProductId": "The id of the product to add",
                        "Quantity": 1
                    }
                    """
            },
            new AiAgentToolAction
            {
                Name = "PurchaseCart",
                Description = "Charge the user to purchase the cart's contents",
                ParametersSampleObject = "{}"
            },
            new AiAgentToolAction
            {
                Name = "ReturnMerchandise",
                Description =
                    """
                    Process a return for a given order and product.
                    The agent should use this action when the customer
                    wants to return a product from a past order.
                    This simply starts the return process, it doesn't complete it, 
                    the agent can check using "GetReturnStatus" to check the status of 
                    the return and update the customer.
                    """,
                ParametersSampleObject =
                    """
                    { 
                        "ProductId": "id of the product to return",
                        "OrderId": "id of the order that contains the product",
                        "Reason": "reason for the return"
                    }
                    """
            },
            new AiAgentToolAction
            {
                Name = "RememberThis",
                Description =
                    """
                    Remember an important fact about this customer for future 
                    interactions. Use this for preferences, allergies, favorite 
                    items, important details, or anything the customer would 
                    expect you to know next time. If a memory with the same 
                    name already exists, update it with the new information.
                    """,
                ParametersSampleObject =
                    """
                    { 
                        "Name": "<unique-key>, like 'allergies', 'favorite-colors', etc.", 
                        "Title": "Up to 15 words, describing the fact to remember",
                        "Description": "Detailed description of the fact to remember" 
                    }
                    """
            },
            new AiAgentToolAction
            {
                Name = "CreateReminder",
                Description =
                    """
                    Set a reminder for the user to follow up on something 
                    at a specific date and time. Use this when the user asks 
                    to be notified or reminded about a product, order, or 
                    any other topic at a later time.
                    """,
                ParametersSchema =
                    """
                    {
                        "type": "object",
                        "properties": {
                            "at": {
                                "type": "string",
                                "format": "date",
                                "description": "The date for the reminder"
                            },
                            "productId": {
                                "type": ["string", "null"],
                                "description": "optional product id the reminder concerns"
                            },
                            "msg": {
                                "type": "string",
                                "description": "what to remind the user about"
                            }
                        },
                        "required": ["at", "productId", "msg"],
                        "additionalProperties": false
                    }
                    """
            }
        ],
        ChatTrimming = new AiAgentChatTrimmingConfiguration(
            new AiAgentSummarizationByTokens()
            {
                MaxTokensBeforeSummarization = 32_768,
                MaxTokensAfterSummarization = 1_024
            },
            new AiAgentHistoryConfiguration(
                expiration: TimeSpan.FromDays(90))
        )
    };

    await store.AI.CreateAgentAsync(aiAgent);
    AnsiConsole.MarkupLine("[green]Shopping agent created.[/]");
}

async Task<bool> HasAiConnectionStringAsync(IDocumentStore store)
{
    var result = await store.Maintenance.SendAsync(
        new GetConnectionStringsOperation(ConnectionStringName, ConnectionStringType.Ai));
    if (result.AiConnectionStrings.ContainsKey(ConnectionStringName) is false)
    {
        AnsiConsole.MarkupLine($"[red]AI connection string '{Markup.Escape(ConnectionStringName)}' not found.[/]");
        AnsiConsole.MarkupLine($"[dim]Please create an AI connection string named '{Markup.Escape(ConnectionStringName)}' in the RavenDB Studio.[/]");
        return false;
    }
    return true;
}

// ── Types ───────────────────────────────────────────────────────────

public class ShoppingAgentAnswer
{
    public string Reply { get; set; }
    public List<string> RelatedProducts { get; set; }
    public List<string> RelatedOrders { get; set; }
    public List<string> Followups { get; set; }
}

public record AddToCartParams(string ProductId, int Quantity);
public record PurchaseCartParams();
public record ReturnMerchandiseParams(string ProductId, string OrderId, string Reason);
public record RememberThisParams(string Name, string Title, string Description);
public record CreateReminderParams(string At, string ProductId, string Msg);

public class ShoppingCart
{
    public string Id { get; set; }
    public List<ShoppingCartItem> Items { get; set; } = [];
}

public class ShoppingCartItem
{
    public string ProductId { get; set; }
    public string ProductName { get; set; }
    public int Quantity { get; set; }
}

public record Product(string Id, string Name);
public record Order(string Id, string Company);
public record Memory(string Title, string Description, string Company, string Id = null);
public record Return(string ProductId, string OrderId, string Reason, DateTime Date, string Status, string Id = null);
public record Reminder(string CompanyId, string ConversationId, string ProductId, string Message, string Id = null);
