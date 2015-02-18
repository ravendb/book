// -----------------------------------------------------------------------
//  <copyright file="ProductPurchasesByCompany.cs" company="Hibernating Rhinos LTD">
//      Copyright (c) Hibernating Rhinos LTD. All rights reserved.
//  </copyright>
// -----------------------------------------------------------------------

using System.Collections.Generic;
using System.Linq;
using Orders;
using Raven.Client.Indexes;

namespace Northwind
{
public class ProductPurchasesByCompany : AbstractIndexCreationTask<Order, ProductPurchasesByCompany.Result>
{
	public class Result
	{
		public string Company;
		public IEnumerable<ProductPurchaseHistory> History;
	}

	public class ProductPurchaseHistory
	{
		public string Product;
		public int TotalPurchases;
		public IEnumerable<ProductPurchases> Purchases;
	}

	public class ProductPurchases
	{
		public int Year;
		public int Quantity;
	}

	public ProductPurchasesByCompany()
	{
		Map = orders =>
			from order in orders
			select new Result
			{
				Company = order.Company,
				History =
					from line in order.Lines
					select new ProductPurchaseHistory
					{
						TotalPurchases = line.Quantity,
						Product = line.Product,
						Purchases = new[]
						{
							new ProductPurchases
							{
								Year = order.OrderedAt.Year,
								Quantity = line.Quantity
							}
						}
					}
			};

		Reduce = results =>
			from result in results
			group result by result.Company into g
			select new Result
			{
				Company = g.Key,
				History = from p in g.SelectMany(x => x.History)
							group p by p.Product into pg
							let productPurchaseHistory = new ProductPurchaseHistory
							{
								Product = pg.Key,
								TotalPurchases = pg.Sum(x => x.TotalPurchases),
								Purchases = from prod in pg.SelectMany(x => x.Purchases)
											group prod by prod.Year into tg
											let productPurchases = new ProductPurchases
											{
												Year = tg.Key,
												Quantity = tg.Sum(x => x.Quantity)
											}
											orderby productPurchases.Year descending
											select productPurchases

							}
							orderby productPurchaseHistory.TotalPurchases descending
							select productPurchaseHistory
			};
	}
}
}