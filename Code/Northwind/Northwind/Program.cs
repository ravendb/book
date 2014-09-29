using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Expressions;
using Orders;
using Raven.Client;
using Raven.Client.Document;
using Raven.Client.Indexes;
using Raven.Client.Linq;

namespace Northwind
{
	internal class Program
	{
		private static DocumentStore _documentStore;

		private static void Main(string[] args)
		{
			_documentStore = new DocumentStore
			{
				Url = "http://ayende-pc:8080",
				DefaultDatabase = "Northwind"
			};

			_documentStore.Initialize();



			//new JustOrderIdAndcompanyName().Execute(documentStore);
		}
	}


	public class Companies_ByCountry : AbstractIndexCreationTask<Company>
	{
		public Companies_ByCountry()
		{
			Map = companies =>
				from company in companies
				select new { company.Address.Country };
		}
	}
	public class JustOrderIdAndcompanyName : AbstractTransformerCreationTask<Order>
	{
		public JustOrderIdAndcompanyName()
		{
			TransformResults = orders =>
				from order in orders
				let company = LoadDocument<Company>(order.Company)
				select new { order.Id, CompanyName = company.Name, order.OrderedAt };
		}

		public class Result
		{
			public string Id { get; set; }
			public string CompanyName { get; set; }
			public DateTime OrderedAt { get; set; }
		}
	}

	public class User
	{
		public string Name;
	}
}