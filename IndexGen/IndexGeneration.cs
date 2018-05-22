using iTextSharp.text.pdf;
using iTextSharp.text.pdf.parser;
using Microsoft.Diagnostics.Runtime;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace ConsoleApp7
{
    class Program
    {
        public class Term
        {
            public string Name;
            public Dictionary<string, List<(int Start, int End, int Count)>> Terms = new Dictionary<string, List<(int Start, int End, int Count)>>(StringComparer.OrdinalIgnoreCase);

            public void AddTerm(string name, int page)
            {
                if (Terms.TryGetValue(name, out var list) == false)
                {
                    Terms[name] = list = new List<(int Start, int End, int Count)>();
                }
                list.Add((page, page, 1));
            }

            public void Complete()
            {
                foreach (var item in Terms)
                {
                    item.Value.Sort((x, y) => x.Start - y.Start);
                    for (int i = 0; i < item.Value.Count - 1; i++)
                    {
                        if (item.Value[i].Start >= item.Value[i + 1].Start || item.Value[i].End + 1 + (item.Value[i].End - item.Value[i].Start )/2 >= item.Value[i + 1].Start)
                        {
                            item.Value[i] = (item.Value[i].Start, item.Value[i + 1].End, item.Value[i].Count + item.Value[i + 1].Count);
                            item.Value.RemoveAt(i + 1);
                            i--;
                        }
                    }

                    if (item.Value.Count > 15)
                    {
                        item.Value.Sort((x, y) => y.Count - x.Count);//sort by count desc

                        item.Value.RemoveRange(15, item.Value.Count - 15);

                        item.Value.Sort((x, y) => x.Start - y.Start);
                    }
                }
            }
        }

        static void Main(string[] args)
        {
            //GeneratePages();

            var pages = new List<(int Page, string Terms)>();

            foreach (var file in Directory.GetFiles(@"f:\book\Output2\", "*.txt"))
            {
                var text = File.ReadAllText(file);
                var page = int.Parse(System.IO.Path.GetFileNameWithoutExtension(file).Split('-')[1]);
                pages.Add((page, text));
            }

            var groupedTerms = JsonConvert.DeserializeObject<Dictionary<string, List<string>>>(File.ReadAllText(@"f:\book\index-terms.json"))
                .GroupBy(x => x.Key.Split(',')[0]).ToDictionary(x => x.Key, x => x.ToList());

            var terms = new List<Term>();

            foreach (var grp in groupedTerms)
            {
                var t = new Term { Name = grp.Key };
                terms.Add(t);

                foreach (var item in grp.Value.OrderByDescending(x => x.Key))
                {
                    foreach (var page in pages)
                    {
                        foreach (var term in item.Value)
                        {
                            if (page.Terms.Contains(term, StringComparison.OrdinalIgnoreCase))
                            {
                                t.AddTerm(item.Key, page.Page);
                            }
                        }
                    }
                }
                t.Complete();
            }

            var chars = new HashSet<char>();

            terms.Sort((x, y) => x.Name.CompareTo(y.Name));

            foreach (var item in terms)
            {
                if (chars.Add(item.Name[0]))
                {
                    Console.WriteLine("**" + item.Name[0] + "**");
                    Console.WriteLine();
                }

                if(item.Terms.Count > 1 && item.Terms.ContainsKey(item.Name) == false)
                {
                    Console.WriteLine("> " + item.Name);
                    Console.WriteLine(">");
                }

                foreach (var t in item.Terms.OrderBy(x => x.Key))
                {
                    if (t.Key == item.Name || item.Terms.Count == 1)
                    {
                        Console.WriteLine("> " + t.Key);
                        Console.WriteLine(">");
                    }
                    else
                    {
                        Console.WriteLine($">> {t.Key}");
                        Console.WriteLine(">>");
                        Console.Write(">>");
                    }
                    Console.WriteLine($"> {string.Join(", ", t.Value.Select(x => x.Start == x.End ? x.Start.ToString() : x.Start + "-" + x.End))}");
                    Console.WriteLine();
                }
            }

        }

        private static Dictionary<string, int> GeneratePages()
        {
            var pdf = new PdfReader(@"f:\book\Output\Inside RavenDB 4.0.pdf");
            var terms = new Dictionary<string, int>();
            for (int i = 23; i < pdf.NumberOfPages; i++)
            {
                var text = PdfTextExtractor.GetTextFromPage(pdf, i);
                File.WriteAllText(@"f:\book\Output\pages-" + i + ".txt", text);
            }

            return terms;
        }
    }
}
