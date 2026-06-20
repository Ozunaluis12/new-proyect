using LoginovaAPI.Data;
using LoginovaAPI.DTOs;
using LoginovaAPI.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LoginovaAPI.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
/// <summary>
/// Controlador para administrar los clientes del sistema.
/// </summary>
public class ClientesController : ControllerBase
{
    private readonly AppDbContext _context;

    /// <summary>
    /// Constructor que inyecta el contexto de datos.
    /// </summary>
    public ClientesController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    /// <summary>
    /// Obtiene la lista completa de clientes.
    /// </summary>
    public async Task<ActionResult<List<Cliente>>> GetAll()
    {
        return Ok(await _context.Clientes.AsNoTracking().ToListAsync());
    }

    [HttpGet("{id:int}")]
    /// <summary>
    /// Obtiene un cliente por su identificador.
    /// </summary>
    public async Task<ActionResult<Cliente>> GetById(int id)
    {
        var cliente = await _context.Clientes.FindAsync(id);
        return cliente is null ? NotFound() : Ok(cliente);
    }

    [HttpPost]
    /// <summary>
    /// Crea un nuevo cliente en la base de datos.
    /// </summary>
    public async Task<ActionResult<Cliente>> Create(ClienteRequest request)
    {
        var cliente = new Cliente
        {
            Nombre = request.Nombre,
            Telefono = request.Telefono,
            Direccion = request.Direccion,
            Ciudad = request.Ciudad,
        };

        _context.Clientes.Add(cliente);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetById), new { id = cliente.Id }, cliente);
    }

    [HttpPut("{id:int}")]
    /// <summary>
    /// Actualiza los datos de un cliente existente.
    /// </summary>
    public async Task<IActionResult> Update(int id, ClienteRequest request)
    {
        var cliente = await _context.Clientes.FindAsync(id);
        if (cliente is null)
        {
            return NotFound();
        }

        cliente.Nombre = request.Nombre;
        cliente.Telefono = request.Telefono;
        cliente.Direccion = request.Direccion;
        cliente.Ciudad = request.Ciudad;

        await _context.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    /// <summary>
    /// Elimina un cliente por su identificador.
    /// </summary>
    public async Task<IActionResult> Delete(int id)
    {
        var cliente = await _context.Clientes.FindAsync(id);
        if (cliente is null)
        {
            return NotFound();
        }

        _context.Clientes.Remove(cliente);
        await _context.SaveChangesAsync();
        return NoContent();
    }
}
