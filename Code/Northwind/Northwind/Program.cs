using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using Orders;
using Raven.Abstractions.Data;
using Raven.Abstractions.Indexing;
using Raven.Client;
using Raven.Client.Connection;
using Raven.Client.Document;
using Raven.Client.Indexes;
using Raven.Client.Linq;
using Raven.Imports.Newtonsoft.Json;

namespace Northwind
{
	public class Program
	{

		private static void Main(string[] args)
		{
			var documentStore = new DocumentStore
			{
				Url = "http://localhost:8080",
				DefaultDatabase = "Northwind",
				ApiKey = "test/DIYUhhpXif"
			};

			documentStore.Initialize();
			new EmployeeOfTheMonth().Execute(documentStore);
			new ProductPurchasesByCompany().Execute(documentStore);
			//new Products_Search().Execute(documentStore);

			using (var session = documentStore.OpenSession())
			{
				var empOfMon = session.Query<EmployeeOfTheMonth.Result, EmployeeOfTheMonth>()
					.Include(x => x.Employee)
					.OrderByDescending(x => x.TotalSales)
					.Where(x => x.Month == "1998-03")
					.First();

				var emp = session.Load<Employee>(empOfMon.Employee);

				Console.WriteLine(emp.FirstName +" " + emp.LastName);

				Console.WriteLine(empOfMon.Employee);
			}

			//new Product_Search().Execute(documentStore);
		}

		private IDocumentSession session;

		readonly Facet[] productQueryFacets = new Facet[]
            {
                new Facet<Product>
                {
                    Name = x => x.Supplier
                },
                new Facet<Product>
                {
                    Name = x => x.Category
                },
                new Facet<Product>
                {
                    Name = x => x.Price,
                    Ranges =
                    {
                        product => product.Price >= 0 && product.Price < 50,
                        product => product.Price >= 50 && product.Price < 100,
                        product => product.Price >= 100 && product.Price < 200,
                        product => product.Price >= 200
                    }
                }
            };
		public SearchResult Search(SearchQuery search)
		{
			var query = session.Advanced.DocumentQuery<Product, Products_Search>()
				.OpenSubclause()
					.Search(x => x.Name, search.Query).Boost(2)
					.Search(x => x.Description, search.Query)
				.CloseSubclause()
				.AndAlso()
				.WhereEquals(x => x.Discontinued, false);

			foreach (var facet in search.Facets)
			{
				query.AndAlso().Where(facet.SearchClause);
			}

			var lazyFacets = query.ToFacetsLazy(productQueryFacets);
			RavenQueryStatistics stats;
			var lazyQuery = query
				.Statistics(out stats)
				.Lazily();

			session.Advanced.Eagerly.ExecuteAllPendingLazyOperations();

			if (stats.TotalResults == 0)
			{
				return SuggestMoreTerms(search);
			}

			var result = new SearchResult
			{
				TotalResults = stats.TotalResults,
				Results = lazyQuery.Value.ToList(),
			};

			AddFacetsToResults(result, lazyFacets.Value.Results);

			return result;
		}

		private void AddFacetsToResults(SearchResult result,
			Dictionary<string, FacetResult> facets)
		{
			var suppliersIds = facets["Supplier"].Values.Select(x => x.Range);
			var categoriesIds = facets["Category"].Values.Select(x => x.Range);

			session.Advanced.Lazily.Load<Supplier>(suppliersIds);
			session.Advanced.Lazily.Load<Category>(categoriesIds);

			session.Advanced.Eagerly.ExecuteAllPendingLazyOperations();

			foreach (var supplierFacetValue in facets["Supplier"].Values)
			{
				result.SuppliersFacets.Add(new FacetSearchResult
				{
					SearchClause = "Supplier: " + supplierFacetValue.Range,
					Count = supplierFacetValue.Hits,
					Name = session.Load<Supplier>(supplierFacetValue.Range).Name
				});
			}

			foreach (var supplierFacetValue in facets["Category"].Values)
			{
				result.CategoriesFacets.Add(new FacetSearchResult
				{
					SearchClause = "Category: " + supplierFacetValue.Range,
					Count = supplierFacetValue.Hits,
					Name = session.Load<Category>(supplierFacetValue.Range).Name
				});
			}

			var priceRange = facets["Price_Range"];
			var priceFacets = new[]
            {
                "Less than 50",
                "50 - 100",
                "100 - 200",
                "200 or higher"
            };
			for (int i = 0; i < 4; i++)
			{
				if (priceRange.Values[i].Hits == 0)
					continue;
				result.PriceFacets.Add(new FacetSearchResult
				{
					SearchClause = "Price_Range: " + priceRange.Values[i].Range,
					Count = priceRange.Values[i].Hits,
					Name = priceFacets[i]
				});
			}
		}

		private SearchResult SuggestMoreTerms(SearchQuery search)
		{
			var dbCmds = session.Advanced.DocumentStore.DatabaseCommands;
			var suggest = dbCmds.Suggest("Products/Search", new SuggestionQuery
			{
				Term = search.Query,
				Field = "Name"
			});
			switch (suggest.Suggestions.Length)
			{
				case 0:
					return new SearchResult
					{
						Message = "No results for: " + search.Query,
					};
				case 1:
					return Search(new SearchQuery
					{
						Query = suggest.Suggestions[0],
						Facets = search.Facets
					});
				default:
					return new SearchResult
					{
						Message = "No results for: " + search.Query,
						Suggestions = suggest.Suggestions
					};
			}
		}
	}

	public class SearchResult
	{
		public int TotalResults;
		public string Message;
		public string[] Suggestions;
		public List<FacetSearchResult> SuppliersFacets = new List<FacetSearchResult>();
		public List<FacetSearchResult> CategoriesFacets = new List<FacetSearchResult>();
		public List<FacetSearchResult> PriceFacets = new List<FacetSearchResult>();
		public List<Product> Results;
	}

	public class FacetSearchResult
	{
		public string SearchClause;
		public string Name;
		public int Count;
	}


	public class SearchQuery
	{
		public List<FacetSearchResult> Facets = new List<FacetSearchResult>();
		public string Query;
	}
	public class Products_Search : AbstractIndexCreationTask<Product>
	{
		public Products_Search()
		{
			Map = products =>
				from product in products
				select new
				{
					product.Name,
					product.Description,
					product.Price,
					product.Supplier,
					product.Category,
					product.Discontinued
				};

			Index(x => x.Name, FieldIndexing.Analyzed);
			Suggestion(x => x.Name);
		}
	}
}